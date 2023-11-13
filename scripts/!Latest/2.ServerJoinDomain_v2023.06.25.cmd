@echo off
echo Script 2 running
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


cd %~dp0bin

powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%~dp0bin\2.ServerJoinDomain_v2023.06.25.ps1"
Echo .
Echo .
Echo .
Echo .
ECHO hit any key to close this window and then server will Reboot

timeout /T 30 /Nobreak

powershell.exe "Restart-Computer -verbose"