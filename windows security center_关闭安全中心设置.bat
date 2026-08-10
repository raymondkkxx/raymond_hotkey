@echo off
:: Request Administrator Privileges
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting Administrative Privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

echo Disabling Windows Defender Real-time Protection...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true" >nul 2>&1

echo Disabling Dev Drive Protection...
powershell -Command "Set-MpPreference -DisableAsyncScanningOnDevVolumes $true" >nul 2>&1

echo.
echo Process finished! Both options have been turned OFF.
timeout /t 3