# Updated: Willie Cornett
# Date: 25/06/2023

#Log Levels 1 Error, 2 Debug, 3 Info
param([bool] $logToFile = 1, [Int32] $CurrentLogLevel = 3)

$ScriptName = Split-Path $PSCommandPath -Leaf

$LogFile = "$PSScriptRoot\4.ServerUpdates_T1Admin_v2023.06.25.log"
$RemoteScriptPath = "\C$\Scripts"


$server=$env:COMPUTERNAME

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



   Function Sleep-Progress($seconds) {
    $s = 0;
    Do {
        $p = [math]::Round(100 - (($seconds - $s) / $seconds * 100));
        Write-Progress -Activity "Waiting..." -Status "$p% Complete:" -SecondsRemaining ($seconds - $s) -PercentComplete $p;
        [System.Threading.Thread]::Sleep(500)
        $s++;
    }
    While($s -lt $seconds);
    
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
			LogMessage -LogLevel:2 "--  Installing post build updates with T1 Admin onto $server. $RunDate" 

            #Update Description on Computer Object in AD
            LogMessage "Updating AD Computer Object with Description"
            $Computer=$env:COMPUTERNAME
            $Computervalue=Get-WmiObject -class Win32_OperatingSystem -ComputerName $env:COMPUTERNAME
            $ComputerSearcher = New-Object DirectoryServices.DirectorySearcher
            $ComputerSearcher.SearchRoot = "LDAP://$("DC=$(($ENV:USERDNSDOMAIN).Replace(".",",DC="))")"
            $ComputerSearcher.Filter = "(&(objectCategory=Computer)(CN=$Computer))"
            $computerObj = [ADSI]$ComputerSearcher.FindOne().Path
            $computerObj.Put( "Description",($Computervalue.Description) )
            $computerObj.SetInfo()
            write-output "Updated Computer AD Object decscription for $Computer"
            Write-Host "Updated Computer AD Object decscription for $Computer" -ForegroundColor Green 

            #Apply latest SCOM Agent Patch
            LogMessage "Applying latest SCOM Agent Patch"
            $latestfolder = gci "\\vmmh1mgt001.healthcare.huarahi.health.govt.nz\packages$\Software Distribution\SCOM\Software\Agent-2019" | sort -Property LastWriteTime -Descending | select -First 1
            $latestfile = Get-ChildItem $latestfolder.FullName -File | Sort-Object LastWriteTime -Descending| Select-Object -First 1
            LogMessage $latestfile.FullName
            #Disable File Open Security Warning
            $env:SEE_MASK_NOZONECHECKS = 1
            Start-Process $latestfile.FullName -ArgumentList "/quiet /passive"
            #Enable File Open Security Warning
            Remove-Item env:SEE_MASK_NOZONECHECKS
            Write-Host "Applied latest SCOM Agent Patch" -ForegroundColor Green  

            ##Update SCOM Agent to use vhal1omm002 - NOT REQUIRED ANYMORE!
            #LogMessage "Updating SCOM Agent to use vhal1omm002"
            #$mma1 = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'  
	        #$mma1.RemoveManagementGroup('ha_Reg_PROD')  
	        #    if ($? -eq 0)  
	        #        {  
		    #            write-host "Management Group ha_Reg_PROD was removed!"  
	        #        }  
	
	        #$mma1.AddManagementGroup('ha_Reg_PROD' , 'vhal1omm002.healthcare.huarahi.health.govt.nz' , 5723)  
	        #    if ($? -eq 0)  
	        #        {  
		    #            write-host "Management group ha_Reg_PROD was added!"  
	        #        }  
	        #$mma1.ReloadConfiguration()  
            #Write-Host "Updating SCOM Agent to use vhal1omm002" -ForegroundColor Green 
                        
		}


LogMessage "Cleanup Autologon Reg Keys and Build Scripts"

reg.exe delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoAdminLogon" /f
reg.exe delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultUserName" /f
reg.exe delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultPassWord" /f
reg.exe delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoLogonCount" /f
Set-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name '!Cleanup' -Value "C:\Admin\Cleanup.cmd"

Write-Host "Cleanup Autologon Reg Keys and Build Scripts" -ForegroundColor Green 

$EndDate = $(Get-Date -displayhint time)
LogMessage ""
LogMessage -LogLevel:2 "========================Script ended $EndDate====================="
LogMessage "============================================================================="



Write-Host "Script 4 completed now waiting now rebooting server ...." -ForegroundColor Green
