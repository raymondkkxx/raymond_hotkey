@echo off
chcp 437 >nul

:: ----------------------------------------------------
:: Auto-request Administrator Privileges
:: ----------------------------------------------------
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: ----------------------------------------------------
:: Main Loop
:: ----------------------------------------------------
:LOOP
cls
echo =======================================================
echo          Ethernet Adapter Toggle Tool
echo =======================================================
echo  INSTRUCTIONS:
echo  1. Press ENTER to toggle between ENABLED and DISABLED.
echo  2. Close this window to exit the script.
echo =======================================================
echo.

:: Automatically detect the primary Ethernet adapter and its status
for /f "tokens=1,2 delims=|" %%A in ('powershell -NoProfile -Command "Get-NetAdapter | Where-Object { $_.PhysicalMediaType -eq '802.3' -or $_.MediaType -eq '802.3' -or $_.Name -like '*Ethernet*' -or $_.Name -like '*以太网*' } | Select-Object -First 1 -Property Name, Status | ForEach-Object { $_.Name + '|' + $_.Status }"') do (
    set "NIC_NAME=%%A"
    set "NIC_STATUS=%%B"
)

:: Fallback if specific Ethernet name filter misses
if "%NIC_NAME%"=="" (
    for /f "tokens=1,2 delims=|" %%A in ('powershell -NoProfile -Command "Get-NetAdapter | Where-Object { $_.HardwareInterface -eq $true } | Select-Object -First 1 -Property Name, Status | ForEach-Object { $_.Name + '|' + $_.Status }"') do (
        set "NIC_NAME=%%A"
        set "NIC_STATUS=%%B"
    )
)

echo Adapter Name   : [%NIC_NAME%]
echo Current Status : [%NIC_STATUS%]
echo.
echo -------------------------------------------------------

if /i "%NIC_STATUS%"=="Up" (
    echo Status: Network is currently ENABLED.
    echo Press ENTER to DISABLE the network adapter...
    echo -------------------------------------------------------
    pause >nul
    echo Processing... Disabling network adapter...
    powershell -NoProfile -Command "Disable-NetAdapter -Name '%NIC_NAME%' -Confirm:$false"
) else (
    echo Status: Network is currently DISABLED.
    echo Press ENTER to ENABLE the network adapter...
    echo -------------------------------------------------------
    pause >nul
    echo Processing... Enabling network adapter...
    powershell -NoProfile -Command "Enable-NetAdapter -Name '%NIC_NAME%' -Confirm:$false"
)

echo Operation completed.
timeout /t 2 >nul
goto LOOP