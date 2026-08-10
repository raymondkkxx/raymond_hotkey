@echo off
setlocal enabledelayedexpansion
title System Restart

:: Execute embedded PowerShell code block for accurate countdown and key monitoring
powershell -NoProfile -ExecutionPolicy Bypass -Command "& {Invoke-Command -ScriptBlock ([Scriptblock]::Create((Get-Content '%~f0' -Raw) -replace '(?s).*?#--- POWERSHELL START ---'))}"

:: Capture PowerShell exit code
set "EXIT_CODE=%ERRORLEVEL%"

if "%EXIT_CODE%"=="1" (
    :: Force immediate restart, /t 0 skips Win11 popup notifications
    shutdown /r /f /t 0
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
Write-Host "  SYSTEM RESTART SCHEDULER" -ForegroundColor White
Write-Host "  --------------------------------------------------" -ForegroundColor White
Write-Host "  " -NoNewline; Write-Host "[ENTER]" -ForegroundColor Red -NoNewline; Write-Host " Restart Immediately" -ForegroundColor White
Write-Host "  " -NoNewline; Write-Host "[SPACE]" -ForegroundColor Green -NoNewline; Write-Host " Cancel and Exit" -ForegroundColor White
Write-Host "  --------------------------------------------------" -ForegroundColor White
Write-Host ""

$sec = 30
while ($sec -ge 0) {
    # Overwrite the current line (`r) to refresh the timer with dynamic colors
    $numStr = $sec.ToString('00')
    Write-Host -NoNewline "`r  Restarting in: " -ForegroundColor White
    Write-Host -NoNewline "$numStr" -ForegroundColor Red
    Write-Host -NoNewline " seconds...   " -ForegroundColor White

    if ($sec -eq 0) {
        Start-Sleep -Milliseconds 500
        break
    }

    # Loop to detect keystrokes over a 1-second interval
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($stopwatch.ElapsedMilliseconds -lt 1000) {
        if ([console]::KeyAvailable) {
            $key = [console]::ReadKey($true).Key
            if ($key -eq 'Enter' -or $key -eq 'Return') {
                Write-Host "`n`n  [!] Restarting immediately..." -ForegroundColor Red
                exit 1
            }
            if ($key -eq 'Spacebar') {
                Write-Host "`n`n  [-] Restart canceled." -ForegroundColor Green
                exit 2
            }
        }
        Start-Sleep -Milliseconds 50
    }
    $sec--
}

Write-Host "`n`n  [!] Time expired. Restarting system..." -ForegroundColor Red
exit 1