@echo off
title Auto Import Task Scheduler - raymond_hotkey

:: 1. Check for administrative privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 2. Set current working directory to the script location
cd /d "%~dp0"

echo ===================================================
echo     Importing Scheduled Task: raymond_hotkey
echo ===================================================

set "XML_FILE=%~dp0raymond_taskschd.msc_backup.xml"

if not exist "%XML_FILE%" (
    echo [ERROR] raymond_taskschd.msc_backup.xml was not found in the current folder!
    echo Please ensure this batch file and raymond_taskschd.msc_backup.xml are in the same directory.
    echo.
    pause
    exit /b
)

:: 3. Retrieve current user SID, dynamically update XML, and register task
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$xmlPath = '%XML_FILE%';" ^
    "$sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value;" ^
    "[xml]$xml = Get-Content $xmlPath;" ^
    "$xml.Task.Principals.Principal.UserId = $sid;" ^
    "Register-ScheduledTask -Xml $xml.OuterXml -TaskName 'raymond_hotkey' -Force | Out-Null"

if %errorlevel% equ 0 (
    echo [SUCCESS] Task 'raymond_hotkey' imported and bound to current user successfully!
) else (
    echo [FAILED] Failed to import the task. Please check system privileges.
)

echo.
pause