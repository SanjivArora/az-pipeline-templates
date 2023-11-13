' SetLogonAsAServiceRight.vbs
' Sample VBScript to set or grant Logon As A Service Right.
' Author: https://www.morgantechspace.com/
' ------------------------------------------------------' 

Dim Arg,strUserName,ConfigFileName,OrgStr,RepStr,inputFile,strInputFile,outputFile,obj 
Set Arg = Wscript.Arguments
'strUserName = "HEALTHCARE\svc_RegSCOMsqlMonit"
'strUserName = InputBox("Please enter username for assigning to Logon as a Service:","Username")
strUserName = Arg(0)
Dim oShell 
Set oShell = CreateObject ("WScript.Shell")
oShell.Run "secedit /export /cfg config.inf", 0, true 
oShell.Run "secedit /import /cfg config.inf /db database.sdb", 0, true

ConfigFileName = "config.inf"
OrgStr = "SeServiceLogonRight ="
RepStr = "SeServiceLogonRight = " & strUserName & ","
Set inputFile = CreateObject("Scripting.FileSystemObject").OpenTextFile("config.inf", 1,1,-1)
strInputFile = inputFile.ReadAll
inputFile.Close
Set inputFile = Nothing

Set outputFile =   CreateObject("Scripting.FileSystemObject").OpenTextFile("config.inf",2,1,-1)
outputFile.Write (Replace(strInputFile,OrgStr,RepStr))
outputFile.Close
Set outputFile = Nothing

oShell.Run "secedit /configure /db database.sdb /cfg config.inf",0,true
set oShell= Nothing
set Arg = Nothing

Set obj = CreateObject("Scripting.FileSystemObject")
obj.DeleteFile("config.inf") 
obj.DeleteFile("database.sdb")

Msgbox "Logon As A Service Right granted to user '"& strUserName &"' using Vbscript code"