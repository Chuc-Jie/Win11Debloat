# Replace the startmenu for all users, when using the default startmenuTemplate this clears all pinned apps
# Credit: https://lazyadmin.nl/win-11/customize-windows-11-start-menu-layout/
function ReplaceStartMenuForAllUsers {
    param (
        $startMenuTemplate = "$script:AssetsPath\Start\start2.bin"
    )

    Write-Host "> 正在移除所有用户开始菜单中的所有固定应用..."

    # Check if template bin file exists
    if (-not (Test-Path $startMenuTemplate)) {
        Write-Host "错误：无法清除开始菜单，脚本文件夹中缺少 start2.bin 文件" -ForegroundColor Red
        Write-Host ""
        return
    }

    # Get path to start menu file for all users
    $userPathString = GetUserDirectory -userName "*" -fileName "AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
    $usersStartMenuPaths = Get-ChildItem -Path $userPathString -ErrorAction SilentlyContinue

    # Go through all users and replace the start menu file
    ForEach ($startMenuPath in $usersStartMenuPaths) {
        ReplaceStartMenu $startMenuTemplate "$($startMenuPath.Fullname)\start2.bin"
    }

    # Also replace the start menu file for the default user profile
    $defaultStartMenuPath = GetUserDirectory -userName "Default" -fileName "AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState" -exitIfPathNotFound $false

    # Create folder if it doesn't exist
    if (-not (Test-Path $defaultStartMenuPath)) {
        new-item $defaultStartMenuPath -ItemType Directory -Force | Out-Null
        Write-Host "已为默认用户配置文件创建 LocalState 文件夹"
    }

    # Copy template to default profile
    Copy-Item -Path $startMenuTemplate -Destination $defaultStartMenuPath -Force
    Write-Host "已为默认用户配置文件替换开始菜单"
    Write-Host ""
}


# Replace the startmenu for all users, when using the default startmenuTemplate this clears all pinned apps
# Credit: https://lazyadmin.nl/win-11/customize-windows-11-start-menu-layout/
function ReplaceStartMenu {
    param (
        $startMenuTemplate = "$script:AssetsPath\Start\start2.bin",
        $startMenuBinFile = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin"
    )

    # Change path to correct user if a user was specified
    if ($script:Params.ContainsKey("User")) {
        $startMenuBinFile = GetStartMenuBinPathForUser -UserName (GetUserName)
    }

    # Check if template bin file exists
    if (-not (Test-Path $startMenuTemplate)) {
        Write-Host "错误：无法替换开始菜单，未找到模板文件" -ForegroundColor Red
        return
    }

    if ([IO.Path]::GetExtension($startMenuTemplate) -ne ".bin" ) {
        Write-Host "错误：无法替换开始菜单，模板文件不是有效的 .bin 文件" -ForegroundColor Red
        return
    }

    $userName = GetStartMenuUserNameFromPath -StartMenuBinFile $startMenuBinFile

    $backupBinFile = $startMenuBinFile + ".bak"

    if (Test-Path $startMenuBinFile) {
        # Backup current start menu file
        Move-Item -Path $startMenuBinFile -Destination $backupBinFile -Force
    }
    else {
        Write-Host "找不到用户 $userName 的原始 start2.bin 文件，未为此用户创建备份" -ForegroundColor Yellow
        New-Item -ItemType File -Path $startMenuBinFile -Force
    }

    # Copy template file
    Copy-Item -Path $startMenuTemplate -Destination $startMenuBinFile -Force

    Write-Host "已为用户 $userName 替换开始菜单"
}

function GetStartMenuBinPathForUser {
    param(
        [string]$UserName
    )

    if ([string]::IsNullOrWhiteSpace($UserName)) {
        return "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin"
    }

    return (GetUserDirectory -userName $UserName -fileName "AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin" -exitIfPathNotFound $false)
}

function GetStartMenuUserNameFromPath {
    param(
        [string]$StartMenuBinFile
    )

    $resolvedUserName = [regex]::Match($StartMenuBinFile, '(?:Users\\)([^\\]+)(?:\\AppData)').Groups[1].Value
    if ([string]::IsNullOrWhiteSpace($resolvedUserName)) {
        return 'unknown'
    }

    return $resolvedUserName
}



function RestoreStartMenuFromBackup {
    param(
        [Parameter(Mandatory)]
        [string]$StartMenuBinFile,
        [Parameter(Mandatory = $false)]
        [string]$BackupFilePath
    )

    $userName = GetStartMenuUserNameFromPath -StartMenuBinFile $StartMenuBinFile
    $backupBinFile = if ([string]::IsNullOrWhiteSpace($BackupFilePath)) {
        $StartMenuBinFile + '.bak'
    }
    else {
        $BackupFilePath
    }
    $currentBinBackup = $StartMenuBinFile + '.restore.bak'

    if (-not (Test-Path -LiteralPath $backupBinFile)) {
        return [PSCustomObject]@{
            UserName = $userName
            Result = $false
            Message = "未找到用户 $userName 的开始菜单备份文件。"
        }
    }

    try {
        if (Test-Path -LiteralPath $StartMenuBinFile) {
            Move-Item -Path $StartMenuBinFile -Destination $currentBinBackup -Force
        }

        Copy-Item -Path $backupBinFile -Destination $StartMenuBinFile -Force
        return [PSCustomObject]@{
            UserName = $userName
            Result = $true
            Message = "已为用户 $userName 还原开始菜单。"
        }
    }
    catch {
        return [PSCustomObject]@{
            UserName = $userName
            Result = $false
            Message = "为用户 $userName 还原开始菜单失败。$($_.Exception.Message)"
        }
    }
}

function RestoreStartMenu {
    param(
        [Parameter(Mandatory = $false)]
        [string]$BackupFilePath
    )

    $targetUserName = GetUserName
    $startMenuBinFile = GetStartMenuBinPathForUser -UserName $targetUserName

    Write-Host "正在从备份还原用户 $targetUserName 的开始菜单..."

    return RestoreStartMenuFromBackup -StartMenuBinFile $startMenuBinFile -BackupFilePath $BackupFilePath
}

function RestoreStartMenuForAllUsers {
    param(
        [Parameter(Mandatory = $false)]
        [string]$BackupFilePath
    )

    $userPathString = GetUserDirectory -userName "*" -fileName "AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
    $usersStartMenuPaths = Get-ChildItem -Path $userPathString -ErrorAction SilentlyContinue
    $results = @()

    Write-Host "正在从备份为所有用户还原开始菜单..."

    foreach ($startMenuPath in $usersStartMenuPaths) {
        $startMenuBinFile = Join-Path $startMenuPath.FullName 'start2.bin'
        $results += RestoreStartMenuFromBackup -StartMenuBinFile $startMenuBinFile -BackupFilePath $BackupFilePath
    }

    $defaultStartMenuPath = GetUserDirectory -userName "Default" -fileName "AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState" -exitIfPathNotFound $false

    if (Test-Path $defaultStartMenuPath) {
        $defaultStartMenuBinFile = Join-Path $defaultStartMenuPath 'start2.bin'
        if (Test-Path -LiteralPath $defaultStartMenuBinFile) {
            try {
                Remove-Item -LiteralPath $defaultStartMenuBinFile -Force
                $results += [PSCustomObject]@{
                    UserName = 'Default'
                    Result   = $true
                    Message  = '已移除默认用户配置文件的 start2.bin。'
                }
            }
            catch {
                $results += [PSCustomObject]@{
                    UserName = 'Default'
                    Result   = $false
                    Message  = "移除默认用户配置文件的 start2.bin 失败。$($_.Exception.Message)"
                }
            }
        }
    }

    if ($results.Count -eq 0) {
        $results += [PSCustomObject]@{
            UserName = 'unknown'
            Result = $false
            Message = '未找到任何用户的开始菜单位置。'
        }
    }

    return $results
}