# Import & execute regfile
function ImportRegistryFile {
    param (
        $message,
        $path
    )

    Write-Host $message

    $usesOfflineHive = $script:Params.ContainsKey("Sysprep") -or $script:Params.ContainsKey("User")
    $regFileDirectory = if ($usesOfflineHive) {
        Join-Path $script:RegfilesPath "Sysprep"
    }
    else {
        $script:RegfilesPath
    }
    $regFilePath = Join-Path $regFileDirectory $path

    if (-not (Test-Path $regFilePath)) {
        $errorMessage = "找不到注册表文件：$path ($regFilePath)"
        $script:RegistryImportFailures++
        Write-Host "错误：$errorMessage" -ForegroundColor Red
        Write-Host ""
        throw $errorMessage
    }

    $regResult = $null
    $offlineHiveLoaded = $false

    try {
        if ($usesOfflineHive) {
            # Sysprep targets Default user, User targets the specified user
            $targetUserName = if ($script:Params.ContainsKey("Sysprep")) { "Default" } else { $script:Params.Item("User") }
            $hiveDatPath = GetUserDirectory -userName $targetUserName -fileName "NTUSER.DAT"

            $global:LASTEXITCODE = 0
            reg load "HKU\Default" $hiveDatPath | Out-Null
            $loadExitCode = $LASTEXITCODE

            if ($loadExitCode -ne 0) {
                throw "导入注册表文件 '$path' 失败。离线配置单元加载失败：无法加载位于 '$hiveDatPath' 的用户配置单元（退出代码：$loadExitCode）"
            }

            $offlineHiveLoaded = $true
        }

        $regResult = Invoke-NonBlocking -ScriptBlock {
            param($targetRegFilePath)
            $result = @{
                Output = @()
                ExitCode = 0
                Error = $null
            }

            try {
                $global:LASTEXITCODE = 0
                $output = reg import $targetRegFilePath 2>&1
                $importExitCode = $LASTEXITCODE

                if ($output) {
                    $result.Output = @($output)
                }
                $result.ExitCode = $importExitCode

                if ($importExitCode -ne 0) {
                    throw "注册表导入失败，'$targetRegFilePath' 的退出代码为 $importExitCode"
                }
            }
            catch {
                $result.Error = $_.Exception.Message
                $result.ExitCode = if ($LASTEXITCODE -ne 0) { $LASTEXITCODE } else { 1 }
            }

            return $result
        } -ArgumentList $regFilePath

        $regOutput = @($regResult.Output)
        $hasSuccess = ($regResult.ExitCode -eq 0) -and -not $regResult.Error

        if ($regOutput) {
            foreach ($line in $regOutput) {
                $lineText = if ($line -is [System.Management.Automation.ErrorRecord]) { $line.Exception.Message } else { $line.ToString() }
                if ($lineText -and $lineText.Length -gt 0) {
                    if ($hasSuccess) {
                        Write-Host $lineText
                    }
                    else {
                        Write-Host $lineText -ForegroundColor Red
                    }
                }
            }
        }

        if (-not $hasSuccess) {
            $details = if ($regResult.Error) { $regResult.Error } else { "退出代码：$($regResult.ExitCode)" }
            Write-Warning "reg import 对 '$path' 失败。回退到 PowerShell 注册表写入器。详情：$details"
            Invoke-RegistryOperationsFromRegFile -RegFilePath $regFilePath
            Write-Host "'$path' 的回退导入已成功。" -ForegroundColor Yellow
        }

        Write-Host ""
    }
    catch {
        $script:RegistryImportFailures++
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
    }
    finally {
        if ($offlineHiveLoaded) {
            $global:LASTEXITCODE = 0
            reg unload "HKU\Default" | Out-Null
            $unloadExitCode = $LASTEXITCODE

            if ($unloadExitCode -ne 0) {
                Write-Warning "导入 '$path' 后卸载注册表配置单元 HKU\Default 失败（退出代码：$unloadExitCode）"
            }
        }
    }
}