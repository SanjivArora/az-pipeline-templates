@echo off
echo Script 4 running
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

powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%~dp0bin\4.ServerUpdates_T1Admin_v2023.06.25.ps1"
Echo .
Echo .
Echo .
Echo .

echo Create LAA! AD group for local admin access
cscript C:\Admin\_hA_Server_Build_Scripts\CreateADGroupLAA!.vbs

echo Update SCOM Agent configuration

sc showsid HealthService
sc sidtype HealthService unrestricted
sc showsid HealthService

echo Grant Local Security Policy Rights for HEALTHCARE\svc_RegSCOMAction
cscript C:\Admin\_hA_Server_Build_Scripts\SetLogonAsAServiceRight.vbs HEALTHCARE\svc_RegSCOMAction

powershell.exe "Restart-Service HealthService -verbose"

echo Removing temporary local Admin account CCL

net user CCL /delete

REM Not Required as GPO adds LAA! AD group to local admin
REM echo Adding LAA! AD group to local admin
REM powershell.exe Add-LocalGroupMember -Group "Administrators" -Member ('HEALTHCARE\LAA!' + $env:COMPUTERNAME)

echo Cleanup C:\Admin folder and save install logs to C:\Admin\ServerBuildLogs
CD C:\Admin
Md C:\Admin\SeverBuildLogs
Move C:\Admin\_hA_Server_Build_Scripts\bin\*.log C:\Admin\SeverBuildLogs

echo Clear Event Logs
powershell.exe "Clear-EventLog -LogName Application, System, Security"

timeout /T 30 /NOBREAK

echo Run Peer Review script
"C:\Admin\Peer Review\Peer-Review.cmd"

powershell.exe "Restart-Computer -verbose"