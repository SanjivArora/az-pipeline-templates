# Auther: David Sulaiman
# Date: 04/05/16
# Updated: Willie Cornett
# Date: 25/06/2023
# Join Domain ( Healthcare, AHSL, NHL, Directory.health)
#          
#======================================================================================= 

#Log Levels 1 Error, 2 Debug, 3 Info
param([bool] $logToFile = 1, [Int32] $CurrentLogLevel = 3)

$ScriptName = Split-Path $PSCommandPath -Leaf

$LogFile = "$PSScriptRoot\2.ServerJoinDomain_v2023.06.25.log"
$RemoteScriptPath = "\C$\Scripts"


$server=$env:COMPUTERNAME

$OS
$OSArch
$Patchingpath
$OSenv

# Read in values from ServerConfig file
$file = Get-Content C:\Admin\_hA_Server_Build_Scripts\ServerConfig.txt | ConvertFrom-StringData

cls

#Logs message, by default to the log file defined by $LogFile alternatively back to the commandline
function LogMessage{
	param(
		[string]$Message,
		[Int32]$LogLevel = 3
	)
	if($LogLevel -le $CurrentLogLevel){
		if($logToFile){
			write-output $Message  | Out-File $LogFile -append
		}else{
			write-output $Message
		}
	}
}





Function Joindomain{
Write-host "Server Domain Join" -ForegroundColor Cyan
        LogMessage "Server Domain Join"


#$AdminUser= Read-Host "Please enter your adm account"
#$domain= Read-Host "Please enter one of the following domain names:  Healthcare , AHSL , NHL , Directory.Health"
#$OU= Read-Host "Please enter OU eg. Northern Region/Production/Servers/Applications/PRT"

$AdminUser = $file.T1Admin
$domain = $file.Domain
$OU = $file.ComputerOU
$OU2 = ""

switch($domain) {
"Healthcare" {$domainName="Healthcare.Huarahi.health.govt.nz"}
"AHSL" {$domainName="ADHB.govt.nz"}
"NHL" {$domainName="NHL.co.nz"}
"Directory.Health" {$domainName="Directory.Health"}

default {write-host "The specified Domain Name is either incorrect or not configured on this script, please try again or contact your administrator" -ForegroundColor Red 
 Exit 
}
}


function Reverse
{ 
 $arr = @($input)
 [array]::reverse($arr)
 $arr
}


$DN = 'DC=' + $DomainName.Replace('.',',DC=')
$T = $OU -split '/' | Reverse

foreach ($i in $T) {
$OU2 = $OU2 + 'OU=' + $i + ','
}
$OU2 = $OU2 + $DN

#$Password=Get-Content "C:\Admin\_hA_Server_Build_Scripts\p.txt" | ConvertTo-SecureString
#$Cred2=New-Object System.Management.Automation.PSCredential("Healthcare\svc_DomainODjoin",$Password)


$AESKeyFilePath = “C:\Admin\_hA_Server_Build_Scripts\aeskey.txt”
$SecurePwdFilePath = “C:\Admin\_hA_Server_Build_Scripts\p.txt”

#use key and password to create local secure password
$AESKey = Get-Content -Path $AESKeyFilePath 
$pwdTxt = Get-Content -Path $SecurePwdFilePath
$Password = $pwdTxt | ConvertTo-SecureString -Key $AESKey

#crete a new psCredential object with required username and password
$X=$Domain + '\' + $AdminUser
$Cred=New-Object System.Management.Automation.PSCredential("Healthcare\Svc_DomainODjoin",$Password)

#Update Scripts 3 and 4
Write-Host "Updating Scripts 3,4  ...." -ForegroundColor Green
New-PSDrive -Name U -PSProvider FileSystem -Root "\\10.69.7.44\packages$\Software Distribution\ServerBuild\Server Builds 2019\Willie\!Latest" -Credential $Cred -Persist

xcopy U:\3*.cmd C:\Admin\_hA_Server_Build_Scripts\ /d /f /y
xcopy U:\4*.cmd C:\Admin\_hA_Server_Build_Scripts\ /d /f /y

xcopy U:\Bin\3*.ps1 C:\Admin\_hA_Server_Build_Scripts\Bin\ /d /f /y
xcopy U:\Bin\4*.ps1 C:\Admin\_hA_Server_Build_Scripts\Bin\ /d /f /y

Remove-PSDrive -Name U


Write-host "Joining $domain " -ForegroundColor Cyan
        LogMessage "Joining $domain"
   Try {add-computer -Credential $Cred -DomainName $domainName -OUPath $OU2
        #add-computer -Credential $domain\$AdminUser -DomainName $domainName -OUPath $OU2 -WhatIf
        #Restart-Computer
        Write-Host "Please restart Server later to complete join domain"
        Write-host "Successfully Joined server to $domainName" -ForegroundColor Green
        LogMessage "Successfully Joined server to $domainName"

}
   Catch {Write-host "Failed joining $domainName " -ForegroundColor Red
        LogMessage "Failed joining $domainName"}



}





function CheckComputerState{
	param(
		[string]$Computer
	)
	
	try
	{
		$PingState = New-Object Net.NetworkInformation.Ping;
		$PingReply = $PingState.Send($Computer);
	}
	catch
	{
		return $false
	}
	
	return ($PingReply.Status -eq "Success");
}
write-output "Starting script logging output to $LogFile"


$RunDate = $(Get-Date -displayhint time)
LogMessage "============================================================================="
LogMessage -LogLevel:2 "========================Script starting $RunDate=================="
LogMessage ""




$fullPathIncFileName = $MyInvocation.MyCommand.Definition
$currentScriptName = $MyInvocation.MyCommand.Name
$currentExecutingPath = $fullPathIncFileName.Replace($currentScriptName, "")
LogMessage "Current Path of executing script: $currentExecutingPath"


        			$RunDate = $(Get-Date -displayhint time)
					if(CheckComputerState $server){
						LogMessage ""
						LogMessage -LogLevel:2 "--  Installing post build updates onto $server. $RunDate" 

						
               Joindomain

						                
                                                
                        
					}
                      


#Set Runonce to Script3
Set-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name '!Script3' -Value "C:\Admin\_hA_Server_Build_Scripts\3.ServerBuildUpdates_PostReboot_v2023.06.25.cmd"


Write-Host "Script 2 completed now rebooting server ...." -ForegroundColor Green

$EndDate = $(Get-Date -displayhint time)
LogMessage ""
LogMessage -LogLevel:2 "========================Script ended $EndDate====================="
LogMessage "============================================================================="

