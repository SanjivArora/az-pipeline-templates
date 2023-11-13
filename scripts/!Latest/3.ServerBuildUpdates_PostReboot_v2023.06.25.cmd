@echo off
echo Script 3 running now
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

echo Activate Windows License using KMS
cscript c:\windows\system32\slmgr.vbs /ipk N69G4-B89J2-4G8F4-WWYCC-J464C
cscript c:\windows\system32\slmgr.vbs /ato


cd %~dp0bin

powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%~dp0bin\3.ServerUpdates_PostReboot_v2023.06.25.ps1"
Echo .
Echo .
Echo .
Echo .

echo "Wait for 10 mins before rebooting server so applications can complete installation"
timeout /T 600 /Nobreak

echo GPO Update
gpupdate /force

powershell.exe "Restart-Computer -verbose"