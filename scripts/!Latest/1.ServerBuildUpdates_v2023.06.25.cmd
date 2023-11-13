@echo off
echo Script 1 running
echo Checking admin rights to run "As administrator" this script.

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for admin permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )
:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B
:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------

echo permission granted

echo Update Server Config settings file, save and close.

notepad C:\Admin\_hA_Server_Build_Scripts\ServerConfig.txt

cd %~dp0bin

powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%~dp0bin\1.ServerPostBuildUpdates_v2023.06.25.ps1"
Echo .
Echo .
Echo .
Echo .

echo CHECK IF GATEWAY IS WORKING:
echo ---------------------------------------------------
REM Check default gateway is working
FOR /F "tokens=3" %%a in ('route print ^| find " 0.0.0.0"') do ping %%a

echo.
echo ###################################################

echo CHECK ARP CACHE CONTAINS GATEWAY:
echo ---------------------------------------------------
arp -a

echo.
echo ###################################################

echo CHECK DNS IS WORKING BY RESOLVING DOMAINS:
echo ---------------------------------------------------
nslookup healthcare.huarahi.health.govt.nz

echo.
echo ###################################################

timeout /T 30 /Nobreak

powershell.exe "Restart-Computer -verbose"