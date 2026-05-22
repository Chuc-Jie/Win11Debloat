[CmdletBinding(SupportsShouldProcess)]
param (
    [switch]$CLI,
    [switch]$Silent,
    [switch]$Sysprep,
    [string]$LogPath,
    [string]$User,
    [switch]$NoRestartExplorer,
    [switch]$CreateRestorePoint,
    [switch]$RunAppsListGenerator,
    [switch]$RunDefaults,
    [switch]$RunDefaultsLite,
    [switch]$RunSavedSettings,
    [string]$Config,
    [string]$Apps,
    [string]$AppRemovalTarget,
    [switch]$RemoveApps,
    [switch]$RemoveAppsCustom,
    [switch]$RemoveGamingApps,
    [switch]$RemoveCommApps,
    [switch]$RemoveHPApps,
    [switch]$RemoveW11Outlook,
    [switch]$ForceRemoveEdge,
    [switch]$DisableDVR,
    [switch]$DisableGameBarIntegration,
    [switch]$EnableWindowsSandbox,
    [switch]$EnableWindowsSubsystemForLinux,
    [switch]$DisableTelemetry,
    [switch]$DisableSearchHistory,
    [switch]$DisableFastStartup,
    [switch]$DisableBitlockerAutoEncryption,
    [switch]$DisableModernStandbyNetworking,
    [switch]$DisableStorageSense,
    [switch]$DisableUpdateASAP,
    [switch]$PreventUpdateAutoReboot,
    [switch]$DisableDeliveryOptimization,
    [switch]$DisableBing,
    [switch]$DisableStoreSearchSuggestions,
    [switch]$DisableSearchHighlights,
    [switch]$DisableDesktopSpotlight,
    [switch]$DisableLockscreenTips,
    [switch]$DisableSuggestions,
    [switch]$DisableLocationServices,
    [switch]$DisableFindMyDevice,
    [switch]$DisableEdgeAds,
    [switch]$DisableBraveBloat,
    [switch]$DisableSettings365Ads,
    [switch]$DisableSettingsHome,
    [switch]$ShowHiddenFolders,
    [switch]$ShowKnownFileExt,
    [switch]$HideDupliDrive,
    [switch]$EnableDarkMode,
    [switch]$DisableTransparency,
    [switch]$DisableAnimations,
    [switch]$TaskbarAlignLeft,
    [switch]$CombineTaskbarAlways, [switch]$CombineTaskbarWhenFull, [switch]$CombineTaskbarNever,
    [switch]$CombineMMTaskbarAlways, [switch]$CombineMMTaskbarWhenFull, [switch]$CombineMMTaskbarNever,
    [switch]$MMTaskbarModeAll, [switch]$MMTaskbarModeMainActive, [switch]$MMTaskbarModeActive,
    [switch]$HideSearchTb, [switch]$ShowSearchIconTb, [switch]$ShowSearchLabelTb, [switch]$ShowSearchBoxTb,
    [switch]$HideTaskview,
    [switch]$DisableStartRecommended,
    [switch]$DisableStartAllApps,
    [switch]$DisableStartPhoneLink,
    [switch]$DisableCopilot,
    [switch]$DisableRecall,
    [switch]$DisableClickToDo,
    [switch]$DisableAISvcAutoStart,
    [switch]$DisablePaintAI,
    [switch]$DisableNotepadAI,
    [switch]$DisableEdgeAI,
    [switch]$DisableWidgets,
    [switch]$HideChat,
    [switch]$EnableEndTask,
    [switch]$EnableLastActiveClick,
    [switch]$ClearStart,
    [string]$ReplaceStart,
    [switch]$ClearStartAllUsers,
    [string]$ReplaceStartAllUsers,
    [switch]$RevertContextMenu,
    [switch]$DisableDragTray,
    [switch]$DisableMouseAcceleration,
    [switch]$DisableStickyKeys,
    [switch]$DisableWindowSnapping,
    [switch]$DisableSnapAssist,
    [switch]$DisableSnapLayouts,
    [switch]$HideTabsInAltTab, [switch]$Show3TabsInAltTab, [switch]$Show5TabsInAltTab, [switch]$Show20TabsInAltTab,
    [switch]$HideHome,
    [switch]$HideGallery,
    [switch]$ExplorerToHome,
    [switch]$ExplorerToThisPC,
    [switch]$ExplorerToDownloads,
    [switch]$ExplorerToOneDrive,
    [switch]$AddFoldersToThisPC,
    [switch]$HideOnedrive,
    [switch]$Hide3dObjects,
    [switch]$HideMusic,
    [switch]$HideIncludeInLibrary,
    [switch]$HideGiveAccessTo,
    [switch]$HideShare,
    [switch]$ShowDriveLettersFirst,
    [switch]$ShowDriveLettersLast,
    [switch]$ShowNetworkDriveLettersFirst,
    [switch]$HideDriveLetters
)

# Check if script is running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If script is not running as administrator ask user if they want to allow it
if (-not $isAdmin) {
    Write-Host "Win11Debloat 必须以管理员身份运行。" -ForegroundColor Red

    $choice = Read-Host "是否以管理员身份重新启动？(y/n)"

    if ($choice -match '^[Yy]$') {
        $elevatedArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $PSCommandPath)

        foreach ($paramName in $PSBoundParameters.Keys) {
            $paramValue = $PSBoundParameters[$paramName]

            if ($paramValue -is [System.Management.Automation.SwitchParameter]) {
                if ($paramValue.IsPresent) {
                    $elevatedArgs += "-$paramName"
                }
            }
            else {
                $elevatedArgs += "-$paramName"
                $elevatedArgs += "$paramValue"
            }
        }

        if ($MyInvocation.UnboundArguments.Count -gt 0) {
            $elevatedArgs += $MyInvocation.UnboundArguments
        }

        Start-Process powershell -ArgumentList $elevatedArgs -Verb RunAs
    }
    exit
}

# Define script-level variables & paths
$script:Version = "2026.05.20"
$configPath = Join-Path $PSScriptRoot 'Config'
$logsPath = Join-Path $PSScriptRoot 'Logs'
$schemasPath = Join-Path $PSScriptRoot 'Schemas'
$scriptsPath = Join-Path $PSScriptRoot 'Scripts'

$script:AppsListFilePath = Join-Path $configPath 'Apps.json'
$script:DefaultSettingsFilePath = Join-Path $configPath 'DefaultSettings.json'
$script:FeaturesFilePath = Join-Path $configPath 'Features.json'
$script:SavedSettingsFilePath = Join-Path $configPath 'LastUsedSettings.json'
$script:CustomAppsListFilePath = Join-Path $configPath 'CustomAppsList'
$script:DefaultLogPath = Join-Path $logsPath 'Win11Debloat.log'
$script:RegfilesPath = Join-Path $PSScriptRoot 'Regfiles'
$script:RegistryBackupsPath = Join-Path $PSScriptRoot 'Backups'
$script:AssetsPath = Join-Path $PSScriptRoot 'Assets'
$script:AppSelectionSchema = Join-Path $schemasPath 'AppSelectionWindow.xaml'
$script:MainWindowSchema = Join-Path $schemasPath 'MainWindow.xaml'
$script:MessageBoxSchema = Join-Path $schemasPath 'MessageBoxWindow.xaml'
$script:AboutWindowSchema = Join-Path $schemasPath 'AboutWindow.xaml'
$script:ApplyChangesWindowSchema = Join-Path $schemasPath 'ApplyChangesWindow.xaml'
$script:SharedStylesSchema = Join-Path $schemasPath 'SharedStyles.xaml'
$script:BubbleHintSchema = Join-Path $schemasPath 'BubbleHint.xaml'
$script:ImportExportConfigSchema = Join-Path $schemasPath 'ImportExportConfigWindow.xaml'
$script:RestoreBackupWindowSchema = Join-Path $schemasPath 'RestoreBackupWindow.xaml'
$script:LoadAppsDetailsScriptPath = Join-Path (Join-Path $scriptsPath 'FileIO') 'LoadAppsDetailsFromJson.ps1'

$script:ControlParams = 'WhatIf', 'Confirm', 'Verbose', 'Debug', 'LogPath', 'Silent', 'Sysprep', 'User', 'NoRestartExplorer', 'RunDefaults', 'RunDefaultsLite', 'RunSavedSettings', 'Config', 'RunAppsListGenerator', 'CLI', 'AppRemovalTarget'

# Script-level variables for GUI elements
$script:GuiWindow = $null
$script:CancelRequested = $false
$script:ApplyProgressCallback = $null
$script:ApplySubStepCallback = $null

# Check if current powershell environment is limited by security policies
if ($ExecutionContext.SessionState.LanguageMode -ne "FullLanguage") {
    Write-Error "Win11Debloat 无法在您的系统上运行，PowerShell 执行被安全策略限制"
    Write-Output "按任意键退出..."
    $null = [System.Console]::ReadKey()
    Exit
}

Clear-Host

# Ensure required Windows command paths are present in PATH for this session.
$system32Path = "$env:SystemRoot\System32"
if ($env:PATH -notmatch "(?i)(^|;)$([regex]::Escape($system32Path))(?=;|$)") {
    $env:PATH = "$env:SystemRoot\System32;$env:SystemRoot;" + $env:PATH
    Write-Warning "PATH 环境变量中缺少 System32 路径，已为本会话添加。"
}

# Display ASCII art launch logo in CLI
Write-Host ""
Write-Host ""
Write-Host "                   " -NoNewline; Write-Host "      ^" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "     / \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "    /   \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "   /     \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  / ===== \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |" -ForegroundColor Blue -NoNewline; Write-Host "  ---  " -ForegroundColor White -NoNewline; Write-Host "|" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |" -ForegroundColor Blue -NoNewline; Write-Host " ( O ) " -ForegroundColor DarkCyan -NoNewline; Write-Host "|" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |" -ForegroundColor Blue -NoNewline; Write-Host "  ---  " -ForegroundColor White -NoNewline; Write-Host "|" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |       |" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host " /|       |\" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "/ |       | \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |  " -ForegroundColor DarkGray -NoNewline; Write-Host "'''" -ForegroundColor Red -NoNewline; Write-Host "  |" -ForegroundColor DarkGray -NoNewline; Write-Host "    *" -ForegroundColor Yellow
Write-Host "                   " -NoNewline; Write-Host "    (" -ForegroundColor Yellow -NoNewline; Write-Host "'''" -ForegroundColor Red -NoNewline; Write-Host ") " -ForegroundColor Yellow -NoNewline; Write-Host "   *  *" -ForegroundColor DarkYellow
Write-Host "                   " -NoNewline; Write-Host "    ( " -ForegroundColor DarkYellow -NoNewline; Write-Host "'" -ForegroundColor Red -NoNewline; Write-Host " )   " -ForegroundColor DarkYellow -NoNewline; Write-Host "*" -ForegroundColor Yellow
Write-Host ""
Write-Host "             Win11Debloat 正在启动..." -ForegroundColor White
Write-Host "                请保持此窗口打开" -ForegroundColor DarkGray
Write-Host ""

# Log script output to 'Win11Debloat.log' at the specified path
if ($LogPath -and (Test-Path $LogPath)) {
    Start-Transcript -Path (Join-Path $LogPath 'Win11Debloat.log') -Append -IncludeInvocationHeader -Force | Out-Null
}
else {
    Start-Transcript -Path $script:DefaultLogPath -Append -IncludeInvocationHeader -Force | Out-Null
}

# Check if script has all required files
if (-not ((Test-Path $script:DefaultSettingsFilePath) -and (Test-Path $script:AppsListFilePath) -and (Test-Path $script:RegfilesPath) -and (Test-Path $script:AssetsPath) -and (Test-Path $script:AppSelectionSchema) -and (Test-Path $script:ApplyChangesWindowSchema) -and (Test-Path $script:SharedStylesSchema) -and (Test-Path $script:BubbleHintSchema) -and (Test-Path $script:RestoreBackupWindowSchema) -and (Test-Path $script:FeaturesFilePath))) {
    Write-Error "Win11Debloat 找不到所需文件，请确认所有脚本文件均存在"
    Write-Output ""
    Write-Output "按任意键退出..."
    $null = [System.Console]::ReadKey()
    Exit
}

# Load feature info from file
$script:Features = @{}
try {
    $featuresData = Get-Content -Path $script:FeaturesFilePath -Raw | ConvertFrom-Json
    foreach ($feature in $featuresData.Features) {
        $script:Features[$feature.FeatureId] = $feature
    }
}
catch {
    Write-Error "无法从 Features.json 文件加载功能信息"
    Write-Output ""
    Write-Output "按任意键退出..."
    $null = [System.Console]::ReadKey()
    Exit
}

# Check if WinGet is installed & if it is, check if the version is at least v1.4
try {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $script:WingetInstalled = $true
    }
    else {
        $script:WingetInstalled = $false
    }
}
catch {
    Write-Error "无法确定 WinGet 是否已安装，winget 命令执行失败：$_"
    $script:WingetInstalled = $false
}

# Show WinGet warning that requires user confirmation, Suppress confirmation if Silent parameter was passed
if (-not $script:WingetInstalled -and -not $Silent) {
    Write-Warning "WinGet 未安装或版本过旧，这可能导致 Win11Debloat 无法移除某些应用"
    Write-Output ""
    Write-Output "按任意键继续..."
    $null = [System.Console]::ReadKey()
}



##################################################################################################################
#                                                                                                                #
#                                                FUNCTION IMPORTS                                                #
#                                                                                                                #
##################################################################################################################

# App removal functions
. "$PSScriptRoot/Scripts/AppRemoval/ForceRemoveEdge.ps1"
. "$PSScriptRoot/Scripts/AppRemoval/RemoveApps.ps1"
. "$PSScriptRoot/Scripts/AppRemoval/GetInstalledAppsViaWinget.ps1"

# CLI functions
. "$PSScriptRoot/Scripts/CLI/AwaitKeyToExit.ps1"
. "$PSScriptRoot/Scripts/CLI/ShowCLILastUsedSettings.ps1"  
. "$PSScriptRoot/Scripts/CLI/ShowCLIDefaultModeAppRemovalOptions.ps1"
. "$PSScriptRoot/Scripts/CLI/ShowCLIDefaultModeOptions.ps1"
. "$PSScriptRoot/Scripts/CLI/ShowCLIAppRemoval.ps1"
. "$PSScriptRoot/Scripts/CLI/ShowCLIMenuOptions.ps1"
. "$PSScriptRoot/Scripts/CLI/PrintPendingChanges.ps1"
. "$PSScriptRoot/Scripts/CLI/PrintHeader.ps1"

# Features functions
. "$PSScriptRoot/Scripts/Features/ExecuteChanges.ps1"
. "$PSScriptRoot/Scripts/Features/CreateSystemRestorePoint.ps1"
. "$PSScriptRoot/Scripts/Features/BackupRegistryFeatureSelection.ps1"
. "$PSScriptRoot/Scripts/Features/BackupRegistrySnapshotCapture.ps1"
. "$PSScriptRoot/Scripts/Features/BackupRegistryState.ps1"
. "$PSScriptRoot/Scripts/Features/RegistryBackupValidation.ps1"
. "$PSScriptRoot/Scripts/Features/RestoreRegistryApplyState.ps1"
. "$PSScriptRoot/Scripts/Features/RestoreRegistryBackup.ps1"
. "$PSScriptRoot/Scripts/Features/DisableStoreSearchSuggestions.ps1"
. "$PSScriptRoot/Scripts/Features/EnableWindowsFeature.ps1"
. "$PSScriptRoot/Scripts/Features/ImportRegistryFile.ps1"
. "$PSScriptRoot/Scripts/Features/ReplaceStartMenu.ps1"
. "$PSScriptRoot/Scripts/Features/RestartExplorer.ps1"

# File I/O functions
. "$PSScriptRoot/Scripts/FileIO/LoadJsonFile.ps1"
. "$PSScriptRoot/Scripts/FileIO/SaveToFile.ps1"
. "$PSScriptRoot/Scripts/FileIO/SaveSettings.ps1"
. "$PSScriptRoot/Scripts/FileIO/LoadSettings.ps1"
. "$PSScriptRoot/Scripts/FileIO/SaveCustomAppsListToFile.ps1"
. "$PSScriptRoot/Scripts/FileIO/ValidateAppslist.ps1"
. "$PSScriptRoot/Scripts/FileIO/LoadAppsFromFile.ps1"
. "$PSScriptRoot/Scripts/FileIO/LoadAppsDetailsFromJson.ps1"
. "$PSScriptRoot/Scripts/FileIO/LoadAppPresetsFromJson.ps1"

# GUI functions
. "$PSScriptRoot/Scripts/GUI/GetSystemUsesDarkMode.ps1"
. "$PSScriptRoot/Scripts/GUI/SetWindowThemeResources.ps1"
. "$PSScriptRoot/Scripts/GUI/AttachShiftClickBehavior.ps1"
. "$PSScriptRoot/Scripts/GUI/ApplySettingsToUiControls.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-MessageBox.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-ConfigWindow.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-ApplyModal.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-AppSelectionWindow.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-RestoreBackupWindow.ps1"
. "$PSScriptRoot/Scripts/GUI/RestoreBackupDialogFeatureLists.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-RestoreBackupDialog.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-MainWindow.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-AboutDialog.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-Bubble.ps1"

# Helper functions
. "$PSScriptRoot/Scripts/Helpers/AddParameter.ps1"
. "$PSScriptRoot/Scripts/Helpers/ResolveUserProfilePath.ps1"
. "$PSScriptRoot/Scripts/Helpers/CheckIfUserExists.ps1"
. "$PSScriptRoot/Scripts/Helpers/CheckModernStandbySupport.ps1"
. "$PSScriptRoot/Scripts/Helpers/GenerateAppsList.ps1"
. "$PSScriptRoot/Scripts/Helpers/GetFriendlyRegistryBackupTarget.ps1"
. "$PSScriptRoot/Scripts/Helpers/GetFriendlyTargetUserName.ps1"
. "$PSScriptRoot/Scripts/Helpers/ImportConfigToParams.ps1"
. "$PSScriptRoot/Scripts/Helpers/GetTargetUserForAppRemoval.ps1"
. "$PSScriptRoot/Scripts/Helpers/Get-RegFileOperations.ps1"
. "$PSScriptRoot/Scripts/Helpers/Test-TargetUserName.ps1"
. "$PSScriptRoot/Scripts/Helpers/GetUserDirectory.ps1"
. "$PSScriptRoot/Scripts/Helpers/GetUserName.ps1"
. "$PSScriptRoot/Scripts/Helpers/RegistryPathHelpers.ps1"
. "$PSScriptRoot/Scripts/Helpers/ApplyRegistryRegFile.ps1"
. "$PSScriptRoot/Scripts/Helpers/TestIfUserIsLoggedIn.ps1"

# Threading functions
. "$PSScriptRoot/Scripts/Threading/DoEvents.ps1"
. "$PSScriptRoot/Scripts/Threading/Invoke-NonBlocking.ps1"



##################################################################################################################
#                                                                                                                #
#                                                  SCRIPT START                                                  #
#                                                                                                                #
##################################################################################################################



# Get current Windows build version
$WinVersion = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' CurrentBuild

# Check if the machine supports Modern Standby, this is used to determine if the DisableModernStandbyNetworking option can be used
$script:ModernStandbySupported = CheckModernStandbySupport

$script:Params = $PSBoundParameters

# Add default Apps parameter when RemoveApps is requested and Apps was not explicitly provided
if ((-not $script:Params.ContainsKey("Apps")) -and $script:Params.ContainsKey("RemoveApps")) {
    $script:Params.Add('Apps', 'Default')
}

$controlParamsCount = 0

# Count how many control parameters are set, to determine if any changes were selected by the user during runtime
foreach ($Param in $script:ControlParams) {
    if ($script:Params.ContainsKey($Param)) {
        $controlParamsCount++
    }
}

# Hide progress bars for app removal, as they block Win11Debloat's output
if (-not ($script:Params.ContainsKey("Verbose"))) {
    $ProgressPreference = 'SilentlyContinue'
}
else {
    Write-Host "已启用详细模式"
    Write-Output ""
    Write-Output "按任意键继续..."
    $null = [System.Console]::ReadKey()

    $ProgressPreference = 'Continue'
}

if ($script:Params.ContainsKey("Sysprep")) {
    GetUserDirectory -userName "Default" | Out-Null

    # Exit script if run in Sysprep mode on Windows 10
    if ($WinVersion -lt 22000) {
        Write-Error "Win11Debloat Sysprep 模式不支持 Windows 10"
        AwaitKeyToExit
    }
}

# Ensure that target user exists, if User or AppRemovalTarget parameter was provided
if ($script:Params.ContainsKey("User")) {
    GetUserDirectory -userName $script:Params.Item("User") | Out-Null
}
if ($script:Params.ContainsKey("AppRemovalTarget")) {
    GetUserDirectory -userName $script:Params.Item("AppRemovalTarget") | Out-Null
}

# Remove LastUsedSettings.json file if it exists and is empty
if ((Test-Path $script:SavedSettingsFilePath) -and ([String]::IsNullOrWhiteSpace((Get-content $script:SavedSettingsFilePath)))) {
    Remove-Item -Path $script:SavedSettingsFilePath -recurse
}

# Default to CLI mode for deployment-targeted parameters.
$launchInCLI = $CLI -or $script:Params.ContainsKey("User") -or $script:Params.ContainsKey("Sysprep") -or $script:Params.ContainsKey("AppRemovalTarget")

# Only run the app selection form if the 'RunAppsListGenerator' parameter was passed to the script
if ($RunAppsListGenerator) {
    PrintHeader "自定义应用列表生成器"

    $result = Show-AppSelectionWindow

    # Show different message based on whether the app selection was saved or cancelled
    if ($result -ne $true) {
        Write-Host "应用选择窗口已关闭且未保存。" -ForegroundColor Red
    }
    else {
        Write-Output "您的应用选择已保存至 'CustomAppsList' 文件，位置："
        Write-Host "$PSScriptRoot" -ForegroundColor Yellow
    }

    AwaitKeyToExit
}

# Change script execution based on provided parameters or user input
if ((-not $script:Params.Count) -or $RunDefaults -or $RunDefaultsLite -or $RunSavedSettings -or $Config -or ($controlParamsCount -eq $script:Params.Count)) {
    if ($RunDefaults -or $RunDefaultsLite) {
        ShowCLIDefaultModeOptions
    }
    elseif ($RunSavedSettings) {
        if (-not (Test-Path $script:SavedSettingsFilePath)) {
            PrintHeader '自定义模式'
            Write-Error "无法找到 LastUsedSettings.json 文件，未进行任何更改"
            AwaitKeyToExit
        }

        ShowCLILastUsedSettings
    }
    elseif ($Config) {
        try {
            ImportConfigToParams -ConfigPath $Config -CurrentBuild $WinVersion -ExpectedVersion '1.0'
        }
        catch {
            Write-Error "$_"
            AwaitKeyToExit
        }

        if (-not $Silent) {
            PrintHeader '自定义模式'
            PrintPendingChanges
            PrintHeader '自定义模式'
        }
    }
    else {
        if ($launchInCLI) {
            $Mode = ShowCLIMenuOptions
        }
        else {
            try {
                $result = Show-MainWindow

                Stop-Transcript
                Exit
            }
            catch {
                Write-Warning "无法加载 WPF GUI（当前环境不支持），将回退到 CLI 模式"
                if (-not $Silent) {
                    Write-Host ""
                    Write-Host "按任意键继续..."
                    $null = [System.Console]::ReadKey()
                }

                $Mode = ShowCLIMenuOptions
            }
        }
    }

    # Add execution parameters based on the mode
    switch ($Mode) {
        # Default mode, loads defaults and app removal options
        '1' { 
            ShowCLIDefaultModeOptions
        }

        # App removal, remove apps based on user selection
        '2' {
            ShowCLIAppRemoval
        }

        # Load last used options from the "LastUsedSettings.json" file
        '3' {
            ShowCLILastUsedSettings
        }
    }
}
else {
    PrintHeader '配置'
}

# If the number of keys in ControlParams equals the number of keys in Params then no modifications/changes were selected
#  or added by the user, and the script can exit without making any changes.
if (($controlParamsCount -eq $script:Params.Keys.Count) -or ($script:Params.Keys.Count -eq 1 -and ($script:Params.Keys -contains 'CreateRestorePoint' -or $script:Params.Keys -contains 'Apps'))) {
    Write-Output "脚本已完成，未进行任何更改。"
    AwaitKeyToExit
}

# Execute all selected/provided parameters using the consolidated function
# (This also handles restore point creation if requested)
ExecuteAllChanges

RestartExplorer

Write-Output ""
Write-Output ""
Write-Output ""
Write-Output "脚本已完成！请查看上方是否有任何错误。"

AwaitKeyToExit
