# Removes apps specified during function call based on the target scope.
function RemoveApps {
    param (
        $appslist
    )

    # Determine target from script-level params, defaulting to AllUsers
    $targetUser = GetTargetUserForAppRemoval

    $appIndex = 0
    $appCount = @($appsList).Count
    $edgeIds = @('Microsoft.Edge', 'XPFFTQ037JWMHS')
    $edgeUninstallSucceeded = $false
    $edgeScheduledTaskAdded = $false

    Foreach ($app in $appsList) {
        if ($script:CancelRequested) {
            return
        }

        $appIndex++

        # Update step name and sub-progress to show which app is being removed (only for bulk removal)
        if ($script:ApplySubStepCallback -and $appCount -gt 1) {
            & $script:ApplySubStepCallback "正在移除应用 ($appIndex/$appCount)" $appIndex $appCount
        }

        Write-Host "正在尝试移除 $app..."

        # Use WinGet only to remove OneDrive and Edge
        if (($app -eq "Microsoft.OneDrive") -or ($edgeIds -contains $app)) {
            if ($script:WingetInstalled -eq $false) {
                Write-Host "WinGet 未安装或版本过旧，无法移除 $app" -ForegroundColor Red
                continue
            }

            $isEdgeId = $edgeIds -contains $app
            $appName = if ($isEdgeId) { 'Microsoft_Edge' } else { $app -replace '\.', '_' }

            # Uninstall app via WinGet, or create a scheduled task to uninstall it later
            if ($script:Params.ContainsKey("User")) {
                if (-not ($isEdgeId -and $edgeScheduledTaskAdded)) {
                    ImportRegistryFile "正在为用户 $(GetUserName) 添加用于卸载 $app 的计划任务..." "Uninstall_$($appName).reg"
                    if ($isEdgeId) { $edgeScheduledTaskAdded = $true }
                }
            }
            elseif ($script:Params.ContainsKey("Sysprep")) {
                if (-not ($isEdgeId -and $edgeScheduledTaskAdded)) {
                    ImportRegistryFile "正在添加用于在新用户登录后卸载 $app 的计划任务..." "Uninstall_$($appName).reg"
                    if ($isEdgeId) { $edgeScheduledTaskAdded = $true }
                }
            }
            else {
                # Uninstall app via WinGet
                $wingetOutput = Invoke-NonBlocking -ScriptBlock {
                    param($appId)
                    winget uninstall --accept-source-agreements --disable-interactivity --id $appId
                } -ArgumentList $app

                $wingetFailed = Select-String -InputObject $wingetOutput -Pattern "Uninstall failed with exit code|No installed package found matching input criteria|No package found matching input criteria" -SimpleMatch:$false
                if ($isEdgeId) {
                    if (-not $wingetFailed) {
                        $edgeUninstallSucceeded = $true
                    }

                    # Prompt immediately after the final selected Edge ID attempt (if all attempts failed)
                    $hasRemainingEdgeIds = $false
                    if ($appIndex -lt $appCount) {
                        $remainingApps = @($appsList)[($appIndex)..($appCount - 1)]
                        $hasRemainingEdgeIds = @($remainingApps | Where-Object { $edgeIds -contains $_ }).Count -gt 0
                    }

                    if (-not $hasRemainingEdgeIds -and -not $edgeUninstallSucceeded) {
                        Write-Host "无法通过 WinGet 卸载 Microsoft Edge" -ForegroundColor Red

                        if ($script:GuiWindow) {
                            $result = Show-MessageBox -Message '无法通过 WinGet 卸载 Microsoft Edge。是否强制卸载？不推荐！' -Title '强制卸载 Microsoft Edge？' -Button 'YesNo' -Icon 'Warning'

                            if ($result -eq 'Yes') {
                                Write-Host ""
                                ForceRemoveEdge
                            }
                        }
                        elseif ($( Read-Host -Prompt "是否强制卸载 Microsoft Edge？不推荐！(y/n)" ) -eq 'y') {
                            Write-Host ""
                            ForceRemoveEdge
                        }
                    }
                }
            }

            continue
        }

        # Use Remove-AppxPackage to remove all other apps
        $appPattern = '*' + $app + '*'

        try {
            switch ($targetUser) {
                "AllUsers" {
                    # Remove installed app for all existing users, and from OS image
                    Invoke-NonBlocking -ScriptBlock {
                        param($pattern)
                        Get-AppxPackage -Name $pattern -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction Continue
                        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like $pattern } | ForEach-Object { Remove-ProvisionedAppxPackage -Online -AllUsers -PackageName $_.PackageName }
                    } -ArgumentList $appPattern
                }
                "CurrentUser" {
                    # Remove installed app for current user only
                    Invoke-NonBlocking -ScriptBlock {
                        param($pattern)
                        Get-AppxPackage -Name $pattern | Remove-AppxPackage -ErrorAction Continue
                    } -ArgumentList $appPattern
                }
                default {
                    # Target is a specific username - remove app for that user only
                    Invoke-NonBlocking -ScriptBlock {
                        param($pattern, $user)
                        $userAccount = New-Object System.Security.Principal.NTAccount($user)
                        $userSid = $userAccount.Translate([System.Security.Principal.SecurityIdentifier]).Value
                        Get-AppxPackage -Name $pattern -User $userSid | Remove-AppxPackage -User $userSid -ErrorAction Continue
                    } -ArgumentList @($appPattern, $targetUser)
                }
            }
        }
        catch {
            if ($DebugPreference -ne "SilentlyContinue") {
                Write-Host "尝试移除 $app 时出现错误" -ForegroundColor Yellow
                Write-Host $psitem.Exception.StackTrace -ForegroundColor Gray
            }
        }
    }

    Write-Host ""
}