@echo off
setlocal enabledelayedexpansion
title Fast Shutdown

:: 调用末尾嵌入的 PowerShell 代码区块，实现精准倒计时与按键监测
powershell -NoProfile -ExecutionPolicy Bypass -Command "& {Invoke-Command -ScriptBlock ([Scriptblock]::Create((Get-Content '%~f0' -Raw) -replace '(?s).*?#--- POWERSHELL START ---'))}"

:: 捕获 PowerShell 返回的退出码
set "EXIT_CODE=%ERRORLEVEL%"

if "%EXIT_CODE%"=="1" (
    :: 强制立即关机，/t 0 可直接跳过 Win11 全屏关机提示弹窗
    shutdown /s /f /t 0
) else if "%EXIT_CODE%"=="2" (
    echo.
    echo  Exiting...
    timeout /t 2 >nul
    exit /b
) else (
    echo.
    echo  [!] Unexpected error. Exit code: %EXIT_CODE%
    echo.
    pause
)
goto :eof

#--- POWERSHELL START ---
Clear-Host
Write-Host ""
Write-Host "  SYSTEM SHUTDOWN SCRIPT" -ForegroundColor Green
Write-Host "  --------------------------------------------------" -ForegroundColor Green
Write-Host "  [ENTER] Shutdown Immediately" -ForegroundColor Green
Write-Host "  [SPACE] Cancel and Exit" -ForegroundColor Green
Write-Host "  --------------------------------------------------" -ForegroundColor Green
Write-Host ""

$sec = 30
while ($sec -ge 0) {
    # 利用回车符 (`r) 覆盖当前行，实现纯数字变红 + 实时刷新
    $numStr =$sec.ToString('00')
    Write-Host -NoNewline "`r  Shutting down in: " -ForegroundColor Green
    Write-Host -NoNewline "$numStr" -ForegroundColor Red
    Write-Host -NoNewline " seconds...   " -ForegroundColor Green

    if ($sec -eq 0) {
        Start-Sleep -Milliseconds 500
        break
    }

    # 1秒内循环检测按键事件
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($stopwatch.ElapsedMilliseconds -lt 1000) {
        if ([console]::KeyAvailable) {
            $key = [console]::ReadKey($true).Key
            if ($key -eq 'Enter' -or $key -eq 'Return') {
                Write-Host "`n`n  [!] Shutting down immediately..." -ForegroundColor Red
                exit 1
            }
            if ($key -eq 'Spacebar') {
                Write-Host "`n`n  [-] Shutdown canceled." -ForegroundColor Green
                exit 2
            }
        }
        Start-Sleep -Milliseconds 50
    }
    $sec--
}

Write-Host "`n`n  [!] Time expired. Shutting down..." -ForegroundColor Red
exit 1