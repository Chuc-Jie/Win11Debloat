function Show-RestoreBackupWindow {
    param(
        [Parameter(Mandatory = $false)]
        [System.Windows.Window]$Owner = $null
    )

    try {
        Write-Host '正在打开还原备份对话框。'

        $dialogResult = Show-RestoreBackupDialog -Owner $Owner
        if (-not $dialogResult -or $dialogResult.Result -eq 'Cancel') {
            Write-Host '用户取消了还原。'
            return
        }

        $successMessage = $null
        $warningMessage = $null

        if ($dialogResult.Result -eq 'RestoreRegistry') {
            $backup = $dialogResult.Backup
            if (-not $backup) {
                throw '已请求还原注册表备份，但未选择备份。'
            }

            Write-Host "用户已确认还原 $($backup.Target) 的注册表。"
            Restore-RegistryBackupState -Backup $backup
            $successMessage = '注册表备份已成功还原。请重启计算机使所有变更生效。'
        }
        elseif ($dialogResult.Result -eq 'RestoreStartMenu') {
            $scope = $dialogResult.StartMenuScope
            $useManualBackupFile = ($dialogResult.UseManualBackupFile -eq $true)
            $backupFilePath = $null
            if ($dialogResult -is [hashtable] -and $dialogResult.ContainsKey('BackupFilePath')) {
                $backupFilePath = $dialogResult['BackupFilePath']
            }
            elseif ($dialogResult.PSObject.Properties.Match('BackupFilePath').Count -gt 0) {
                $backupFilePath = $dialogResult.BackupFilePath
            }

            if ($useManualBackupFile -and [string]::IsNullOrWhiteSpace($backupFilePath)) {
                throw '开始菜单还原已取消：未选择备份文件。'
            }

            $result = if ($scope -eq 'AllUsers') {
                RestoreStartMenuForAllUsers -BackupFilePath $backupFilePath
            }
            else {
                RestoreStartMenu -BackupFilePath $backupFilePath
            }

            $resultEntries = @($result)
            $successCount = @($resultEntries | Where-Object { $_.Result -eq $true }).Count
            $failedEntries = @($resultEntries | Where-Object { $_.Result -ne $true })

            if ($successCount -eq 0) {
                $errorSummary = ($resultEntries | ForEach-Object { $_.Message }) -join [Environment]::NewLine
                throw "无法还原开始菜单备份。`n$errorSummary"
            }

            if ($failedEntries.Count -gt 0) {
                $failureSummary = ($failedEntries | ForEach-Object { $_.Message }) -join [Environment]::NewLine
                $warningMessage = "开始菜单备份已成功为 $successCount 个用户还原。`n部分用户无法还原：`n$failureSummary"
            }
            else {
                if ($scope -eq 'AllUsers') {
                    $successMessage = "开始菜单备份已成功为所有用户还原。变更将在用户下次登录时生效。"
                }
                else {
                    $successMessage = "开始菜单备份已成功为当前用户还原。变更将在你下次登录时生效。"
                }
            }
        }

        if ($warningMessage) {
            Write-Host "$warningMessage"
            Show-MessageBox -Title '备份已还原' -Message $warningMessage -Icon Warning
        }
        elseif ($successMessage) {
            Write-Host "$successMessage"
            Show-MessageBox -Title '备份已还原' -Message $successMessage -Icon Success
        }
    }
    catch {
        $errorMessage = if ($_.Exception.Message) { $_.Exception.Message } else { '发生了意外错误。' }
        Write-Error "还原操作失败：$errorMessage"
        Show-MessageBox -Title '错误' -Message "还原失败：$errorMessage" -Icon Error
    }
}
