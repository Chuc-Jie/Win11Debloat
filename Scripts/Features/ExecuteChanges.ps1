# Executes a single parameter/feature based on its key
# Parameters:
#   $paramKey - The parameter name to execute
function ExecuteParameter {
    param (
        [string]$paramKey
    )
    
    # Check if this feature has metadata in Features.json
    $feature = $null
    if ($script:Features.ContainsKey($paramKey)) {
        $feature = $script:Features[$paramKey]
    }
    
    # If feature has RegistryKey and ApplyText, use dynamic ImportRegistryFile
    if ($feature -and $feature.RegistryKey -and $feature.ApplyText) {
        ImportRegistryFile "> $($feature.ApplyText)" $feature.RegistryKey
        
        # Handle special cases that have additional logic after ImportRegistryFile
        switch ($paramKey) {
            'DisableBing' {
                # Also remove the app package for Bing search
                RemoveApps 'Microsoft.BingSearch'
            }
            'DisableCopilot' {
                # Also remove the app package for Copilot
                RemoveApps 'Microsoft.Copilot'
            }
        }
        return
    }
    
    # Handle features without RegistryKey or with special logic
    switch ($paramKey) {
        'RemoveApps' {
            Write-Host "> 正在为 $(GetFriendlyTargetUserName) 卸载所选应用..."
            $appsList = GenerateAppsList

            if ($appsList.Count -eq 0) {
                Write-Host "没有选择有效的待卸载应用" -ForegroundColor Yellow
                Write-Host ""
                return
            }

            Write-Host "已选择 $($appsList.Count) 个待卸载的应用"
            RemoveApps $appsList
        }
        'RemoveAppsCustom' {
            Write-Host "> 正在卸载所选应用..."
            $appsList = LoadAppsFromFile $script:CustomAppsListFilePath

            if ($appsList.Count -eq 0) {
                Write-Host "没有选择有效的待卸载应用" -ForegroundColor Yellow
                Write-Host ""
                return
            }

            Write-Host "已选择 $($appsList.Count) 个待卸载的应用"
            RemoveApps $appsList
        }
        'RemoveCommApps' {
            $appsList = 'Microsoft.windowscommunicationsapps', 'Microsoft.People'
            Write-Host "> 正在卸载邮件、日历和人脉应用..."
            RemoveApps $appsList
            return
        }
        'RemoveW11Outlook' {
            $appsList = 'Microsoft.OutlookForWindows'
            Write-Host "> 正在卸载新版 Outlook for Windows 应用..."
            RemoveApps $appsList
            return
        }
        'RemoveGamingApps' {
            $appsList = 'Microsoft.GamingApp', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxGamingOverlay'
            Write-Host "> 正在卸载游戏相关应用..."
            RemoveApps $appsList
            return
        }
        'RemoveHPApps' {
            $appsList = 'AD2F1837.HPAIExperienceCenter', 'AD2F1837.HPJumpStarts', 'AD2F1837.HPPCHardwareDiagnosticsWindows', 'AD2F1837.HPPowerManager', 'AD2F1837.HPPrivacySettings', 'AD2F1837.HPSupportAssistant', 'AD2F1837.HPSureShieldAI', 'AD2F1837.HPSystemInformation', 'AD2F1837.HPQuickDrop', 'AD2F1837.HPWorkWell', 'AD2F1837.myHP', 'AD2F1837.HPDesktopSupportUtilities', 'AD2F1837.HPQuickTouch', 'AD2F1837.HPEasyClean', 'AD2F1837.HPConnectedMusic', 'AD2F1837.HPFileViewer', 'AD2F1837.HPRegistration', 'AD2F1837.HPWelcome', 'AD2F1837.HPConnectedPhotopoweredbySnapfish', 'AD2F1837.HPPrinterControl'
            Write-Host "> 正在卸载 HP 应用..."
            RemoveApps $appsList
            return
        }
        'DisableWidgets' {
            Write-Host "> 正在禁用任务栏和锁屏上的小组件..."
            # Stop widgets related processes before removing the app packages to prevent potential issues
            Get-Process *Widget* | Stop-Process

            RemoveApps 'Microsoft.StartExperiencesApp','MicrosoftWindows.Client.WebExperience','Microsoft.WidgetsPlatformRuntime'
        }
        "EnableWindowsSandbox" {
            Write-Host "> 正在启用 Windows 沙盒..."
            EnableWindowsFeature "Containers-DisposableClientVM"
            Write-Host ""
            return
        }
        "EnableWindowsSubsystemForLinux" {
            Write-Host "> 正在启用适用于 Linux 的 Windows 子系统..."
            EnableWindowsFeature "VirtualMachinePlatform"
            EnableWindowsFeature "Microsoft-Windows-Subsystem-Linux"
            Write-Host ""
            return
        }
        'ClearStart' {
            Write-Host "> 正在移除用户 $(GetUserName) 开始菜单中所有已固定的应用..."
            ReplaceStartMenu
            Write-Host ""
            return
        }
        'ReplaceStart' {
            Write-Host "> 正在为用户 $(GetUserName) 替换开始菜单..."
            ReplaceStartMenu $script:Params.Item("ReplaceStart")
            Write-Host ""
            return
        }
        'ClearStartAllUsers' {
            ReplaceStartMenuForAllUsers
            return
        }
        'ReplaceStartAllUsers' {
            ReplaceStartMenuForAllUsers $script:Params.Item("ReplaceStartAllUsers")
            return
        }
        'DisableStoreSearchSuggestions' {
            if ($script:Params.ContainsKey("Sysprep")) {
                Write-Host "> 正在为所有用户禁用开始菜单中的 Microsoft Store 搜索建议..."
                DisableStoreSearchSuggestionsForAllUsers
                Write-Host ""
                return
            }

            Write-Host "> 正在为用户 $(GetUserName) 禁用 Microsoft Store 搜索建议..."
            DisableStoreSearchSuggestions
            Write-Host ""
            return
        }
    }
}


# Executes all selected parameters/features
function ExecuteAllChanges {    
    $script:RegistryImportFailures = 0

    # Build list of actionable parameters (skip control params and data-only params)
    $actionableKeys = @()
    foreach ($paramKey in $script:Params.Keys) {
        if ($script:ControlParams -contains $paramKey) { continue }
        if ($paramKey -eq 'Apps') { continue }
        if ($paramKey -eq 'CreateRestorePoint') { continue }
        $actionableKeys += $paramKey
    }

    $hasRegistryBackedFeature = $false
    foreach ($paramKey in $actionableKeys) {
        if (-not $script:Features.ContainsKey($paramKey)) { continue }

        $feature = $script:Features[$paramKey]
        if ($feature -and -not [string]::IsNullOrWhiteSpace([string]$feature.RegistryKey)) {
            $hasRegistryBackedFeature = $true
            break
        }
    }
    
    $totalSteps = $actionableKeys.Count
    if ($hasRegistryBackedFeature) { $totalSteps++ }
    if ($script:Params.ContainsKey("CreateRestorePoint")) { $totalSteps++ }
    $currentStep = 0

    if ($hasRegistryBackedFeature) {
        $currentStep++
        if ($script:ApplyProgressCallback) {
            & $script:ApplyProgressCallback $currentStep $totalSteps "正在创建注册表备份..."
        }

        Write-Host "> 正在创建注册表备份..."
        try {
            New-RegistrySettingsBackup -ActionableKeys $actionableKeys | Out-Null
        }
        catch {
            throw "应用更改前注册表备份失败。$($_.Exception.Message)"
        }
    }

    # Create restore point if requested (CLI only - GUI handles this separately)
    if ($script:Params.ContainsKey("CreateRestorePoint")) {
        $currentStep++
        if ($script:ApplyProgressCallback) {
            & $script:ApplyProgressCallback $currentStep $totalSteps "正在创建系统还原点，这可能需要一些时间..."
        }
        Write-Host "> 正在创建系统还原点..."
        CreateSystemRestorePoint
        Write-Host ""
    }
    
    # Execute all parameters
    foreach ($paramKey in $actionableKeys) {
        if ($script:CancelRequested) { 
            return
        }

        $currentStep++
        
        # Get friendly name for the step
        $stepName = $paramKey
        if ($script:Features.ContainsKey($paramKey)) {
            $feature = $script:Features[$paramKey]
            if ($feature.ApplyText) {
                # Prefer explicit ApplyText when provided
                $stepName = $feature.ApplyText
            } elseif ($feature.Label) {
                # Fallback: use label from Features.json
                $stepName = $feature.Label
            }
        }
        
        if ($script:ApplyProgressCallback) {
            & $script:ApplyProgressCallback $currentStep $totalSteps $stepName
        }
        
        ExecuteParameter -paramKey $paramKey
    }

    if ($script:RegistryImportFailures -gt 0) {
        Write-Host ""
        Write-Host "$($script:RegistryImportFailures) 项注册表导入更改失败。详情请见上方输出。" -ForegroundColor Yellow
    }
}