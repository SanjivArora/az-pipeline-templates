@echo off
echo Script 5 running
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

cd C:\Admin\_hA_Server_Build_Scripts

echo Update SCOM Agent configuration

echo Grant Local Security Policy Rights for HEALTHCARE\svc_RegSCOMsqlMonit
cscript C:\Admin\_hA_Server_Build_Scripts\SetLogonAsAServiceRight.vbs HEALTHCARE\svc_RegSCOMsqlMonit

echo Grant Logon as a Service Policy Rights for HEALTHCARE\svc_RegSCOMAction and HEALTHCARE\svc_RegSCOMsqlMonit
cscript C:\Admin\_hA_Server_Build_Scripts\SetAllowLogOnLocally.vbs HEALTHCARE\svc_RegSCOMAction
cscript C:\Admin\_hA_Server_Build_Scripts\SetAllowLogOnLocally.vbs HEALTHCARE\svc_RegSCOMsqlMonit