' CreateADGroupLAA!.vbs
' Creates LAA! group in Active Directory for Local Admin access
' Author: Willie Cornett
' ------------------------------------------------------' 
Option Explicit
Dim strGroupName,wshShell
Dim objRootLDAP,objContainer,objNewGroup
Const ADS_GROUP_TYPE_UNIVERSAL_GROUP = &h8
Const ADS_GROUP_TYPE_SECURITY_ENABLED = &h80000000
Set wshShell = WScript.CreateObject("WScript.Shell")
strGroupName = "LAA!" & wshShell.ExpandEnvironmentStrings("%COMPUTERNAME%")
Set objRootLDAP = GetObject("LDAP://rootDSE")
Set objContainer = GetObject("LDAP://ou=Local Admin Groups,ou=Server Groups,ou=Groups,ou=Production,ou=Northern Region,DC=healthcare,DC=HUARAHI,DC=HEALTH,DC=GOVT,DC=NZ")
Set objNewGroup = objContainer.Create("Group", "cn=" & strGroupName)
objNewGroup.Put "sAMAccountName", strGroupName
objNewGroup.Put "groupType", ADS_GROUP_TYPE_UNIVERSAL_GROUP Or ADS_GROUP_TYPE_SECURITY_ENABLED
objNewGroup.Put "Description", "Provides Local Admin access for server " & wshShell.ExpandEnvironmentStrings("%COMPUTERNAME%")
objNewGroup.SetInfo
 
WScript.Echo "New AD Group " & strGroupName & " created for server " & wshShell.ExpandEnvironmentStrings("%COMPUTERNAME%")

WScript.Quit