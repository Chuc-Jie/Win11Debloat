function Load-RegistryBackupFromFile {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    if (-not (Test-Path -LiteralPath $FilePath)) {
        throw "未找到备份文件：$FilePath"
    }

    try {
        $rawBackup = Get-Content -LiteralPath $FilePath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "读取备份文件 '$FilePath' 失败。该文件不是有效的 JSON。"
    }

    return Normalize-RegistryBackup -Backup $rawBackup
}

function Normalize-RegistryBackup {
    param(
        [Parameter(Mandatory)]
        $Backup
    )

    $errors = New-Object System.Collections.Generic.List[string]

    if (-not $Backup.PSObject.Properties['Version']) {
        $errors.Add('缺少属性：Version')
    }
    elseif ([string]$Backup.Version -ne '1.0') {
        $errors.Add("不支持的备份版本 '$($Backup.Version)'。")
    }

    if (-not $Backup.PSObject.Properties['BackupType']) {
        $errors.Add('缺少属性：BackupType')
    }
    elseif ([string]$Backup.BackupType -ne 'RegistryState') {
        $errors.Add("不支持的 BackupType '$($Backup.BackupType)'。")
    }

    $normalizedTarget = ''
    if (-not $Backup.PSObject.Properties['Target'] -or [string]::IsNullOrWhiteSpace([string]$Backup.Target)) {
        $errors.Add('缺少属性：Target')
    }
    else {
        $normalizedTarget = [string]$Backup.Target

        if ($normalizedTarget -eq 'DefaultUserProfile') {
            # Valid target format.
        }
        elseif ($normalizedTarget -like 'User:*') {
            $targetUserName = $normalizedTarget.Substring(5)
            $targetValidation = Test-TargetUserName -UserName $targetUserName
            if (-not $targetValidation.IsValid) {
                $errors.Add("无效的用户 '$normalizedTarget'")
            }
        }
        elseif ($normalizedTarget -like 'CurrentUser:*') {
            $targetCurrentUserName = $normalizedTarget.Substring(12)
            if ([string]::IsNullOrWhiteSpace($targetCurrentUserName) -or ($targetCurrentUserName -ne $env:USERNAME)) {
                 $errors.Add("备份是为 '$targetCurrentUserName' 创建的，与当前用户 '$env:USERNAME' 不匹配。")
            }
        }
        else {
            $errors.Add("不支持的 Target '$normalizedTarget'。")
        }
    }

    $registryKeys = @()
    if (-not $Backup.PSObject.Properties['RegistryKeys']) {
        $errors.Add('缺少属性：RegistryKeys')
    }
    else {
        $registryKeys = @($Backup.RegistryKeys)
    }

    $normalizedKeys = @()
    foreach ($keySnapshot in $registryKeys) {
        $normalizedKeys += @(Normalize-RegistryKeySnapshot -Snapshot $keySnapshot)
    }

    $selectedFeatureParseResult = Get-NormalizedSelectedFeatureIdsFromBackup -Backup $Backup
    $selectedFeatures = @($selectedFeatureParseResult.SelectedFeatures)
    foreach ($selectedFeatureParseError in @($selectedFeatureParseResult.Errors)) {
        $errors.Add([string]$selectedFeatureParseError)
    }

    $allowListValidationErrors = @(Test-RegistryBackupMatchesSelectedFeatures -SelectedFeatureIds @($selectedFeatures) -Target $normalizedTarget -RegistryKeys @($normalizedKeys))
    foreach ($allowListValidationError in $allowListValidationErrors) {
        $errors.Add([string]$allowListValidationError)
    }

    if ($errors.Count -gt 0) {
        Write-Error "备份校验失败：$($errors -join ' ')"
        if ($errors.Count -eq 1) {
            throw ("校验失败：$($errors[0])")
        }
        else {
            throw ("校验失败，共 $($errors.Count) 个错误。请查看控制台输出获取详情。")
        }
    }

    return [PSCustomObject]@{
        Version = [string]$Backup.Version
        BackupType = [string]$Backup.BackupType
        CreatedAt = [string]$Backup.CreatedAt
        CreatedBy = [string]$Backup.CreatedBy
        ComputerName = [string]$Backup.ComputerName
        Target = $normalizedTarget
        SelectedFeatures = @($selectedFeatures)
        RegistryKeys = @($normalizedKeys)
    }
}

function Restore-RegistryBackupState {
    param(
        [Parameter(Mandatory)]
        $Backup
    )

    $friendlyTarget = GetFriendlyRegistryBackupTarget -Target ([string]$Backup.Target)

    $restoreAction = {
        param($normalizedBackup)

        Write-Host "正在从 $(@($normalizedBackup.RegistryKeys).Count) 个根快照应用注册表还原。"
        foreach ($rootSnapshot in @($normalizedBackup.RegistryKeys)) {
            Restore-RegistryKeySnapshot -Snapshot $rootSnapshot
        }
    }

    Write-Host "正在为 $friendlyTarget 开始还原。"

    if ($Backup.Target -eq 'DefaultUserProfile' -or $Backup.Target -like 'User:*') {
        Write-Host "还原需要加载目标用户配置单元。"
        Invoke-WithLoadedRestoreHive -Target $Backup.Target -ScriptBlock $restoreAction -ArgumentObject $Backup
        Write-Host "$friendlyTarget 还原已完成。"
        return
    }

    & $restoreAction $Backup
    Write-Host "$friendlyTarget 还原已完成。"
}
