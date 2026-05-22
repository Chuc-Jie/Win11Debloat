# Saves the current settings, excluding control parameters, to 'LastUsedSettings.json' file
function SaveSettings {
    $settings = @{
        "Version" = "1.0"
        "Settings" = @()
    }
    
    foreach ($param in $script:Params.Keys) {
        if ($script:ControlParams -notcontains $param) {
            $value = $script:Params[$param]

            $settings.Settings += @{
                "Name" = $param
                "Value" = $value
            }
        }
    }

    if (-not (SaveToFile -Config $settings -FilePath $script:SavedSettingsFilePath)) {
        Write-Output ""
        Write-Host "错误：保存设置到 LastUsedSettings.json 文件失败" -ForegroundColor Red
    }
}