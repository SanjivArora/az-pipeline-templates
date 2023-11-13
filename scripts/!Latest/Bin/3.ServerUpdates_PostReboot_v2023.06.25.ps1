# Updated: Willie Cornett
# Date: 25/06/2023

#Log Levels 1 Error, 2 Debug, 3 Info
param([bool] $logToFile = 1, [Int32] $CurrentLogLevel = 3)

$ScriptName = Split-Path $PSCommandPath -Leaf

$LogFile = "$PSScriptRoot\3.ServerUpdates_PostReboot_v2023.06.25.log"
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


Function Install_SCCM_client{
Param 
(
[string]$ComputerName
)

    Write-Host "Installing SCCM Client ...." -ForegroundColor Cyan
    
    LogMessage "Installing SCCM Client on $ComputerName"
     
     Try{
   
    cmd /c "$PSScriptRoot\SCCM_Client\ccmsetup.exe /forceinstall SMSSITECODE=PRI SMSMP=VMMH1MGT001.healthcare.huarahi.health.govt.nz `
	SMSSLP=VMMH1MGT001.healthcare.huarahi.health.govt.nz FSP=VMMH1MGT001.healthcare.huarahi.health.govt.nz `
	CCMLOGLEVEL=0 CCMLOGMAXHISTORY=10 CCMLOGMAXSIZE=10485760"
    
    Write-Host "Successfully pushed SCCM Client ...." -ForegroundColor Green
    
    LogMessage "Successfully pushed SCCM Client on $ComputerName"
        }
    
     Catch{Write-Host "Failed installing SCCM Client ...." -ForegroundColor Red
    
    LogMessage "Failed installing SCCM Client on $ComputerName"} 
   }


Function Install_XDR_client{
Param 
(
[string]$ComputerName
)

    Write-Host "Installing XDR Client ...." -ForegroundColor Cyan
    
    LogMessage "Installing XDR Client on $ComputerName"
     
     Try{
   
    cmd /c "$PSScriptRoot\DSA_Install\EndpointBasecamp -s"
    
    Write-Host "Successfully pushed XDR Client ...." -ForegroundColor Green
    
    LogMessage "Successfully pushed XDR Client on $ComputerName"
        }
    
     Catch{Write-Host "Failed installing XDR Client ...." -ForegroundColor Red
    
    LogMessage "Failed installing XDR Client on $ComputerName"} 
   }
    

  Function Install_DSA{
Param 
(
[string]$ComputerName
)
    Write-host "Installing DSA on server $server ..." -ForegroundColor Cyan
    LogMessage "Installing DSA on server $server ..."

     Try {    
    
       cmd /c  msiexec  /i "$PSScriptRoot\DSA_Install\Agent-Core-Windows-20.0.0-5995.x86_64.msi" /qn /l "$PSScriptRoot\Agent-Core-Windows-20.0.0-5995.x86_64.log"
       If (Test-Path 'C:\Program Files\Trend Micro\Deep Security Agent\dsa_control.cmd'){
        do
        {
            # $dsm = Read-Host -Prompt 'Choose 1 or 0?  Prod (1) or Non-Prod (0)'
            $dsm = $file.Prod
        }
        until (@(0,1) -contains $dsm)
        		& 'C:\Program Files\Trend Micro\Deep Security Agent\dsa_control.cmd' -r
		
		if ($dsm -eq 0)
		{			
			# & 'C:\Program Files\Trend Micro\Deep Security Agent\dsa_control.cmd' -a dsm://vhal$($dsm)avs011.healthcare.HUARAHI.HEALTH.GOVT.NZ:4120/ "policyid:33" "groupid:19"
			& $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -a dsm://vhal0avs012.healthcare.HUARAHI.HEALTH.GOVT.NZ:4120/ "policyid:25" "groupid:25"
		
		} elseif ($dsm -eq 1)
		{		
			# & 'C:\Program Files\Trend Micro\Deep Security Agent\dsa_control.cmd' -a dsm://vhal$($dsm)avs011.healthcare.HUARAHI.HEALTH.GOVT.NZ:4120/ "policyid:33" "groupid:19"
			& $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -a dsm://vhal1avs011.healthcare.HUARAHI.HEALTH.GOVT.NZ:4120/ "policyid:33" "groupid:19"
		}
      }
          Write-host "Successfully Installed DSA on server $server ..." -ForegroundColor Green
          LogMessage "Successfully Installed DSA on server $server ..."
       }
    Catch {
    Write-host "Error Installing DSA Client ..."
    LogMessage "Error Installing DSA Client on $server"
          }
    }

  
   
       
   Function Install_SCOMClient{
       Param 
       (
       [string]$ComputerName
       )
            Write-host "Installing SCOM Client (Prod) on server $server ..."
            LogMessage "Installing SCOM Client (Prod) on server $server ..."

            Start-Process -wait "$PSScriptRoot\SCOM_Agent\_build_script_install.cmd"

            Write-host "Installed SCOM Client (Prod) on server $server ..." -ForegroundColor Green
            LogMessage "Installed SCOM Client (Prod) on server $server ..."
 
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
			LogMessage -LogLevel:2 "--  Installing post build updates onto $server. $RunDate" 

            Install_SCCM_client -ComputerName $server 
            Install_SCOMClient -ComputerName $server 
            Install_DSA -ComputerName $server
            Install_XDR_client -ComputerName $server        
                        
		}


#Apply TLS Hardening
LogMessage "Applying TLS Hardening"
#Invoke-Command {reg import "C:\Admin\_hA_Server_Build_Scripts\TLS Hardening\20230324 (Latest)\SCHANNEL hANZ Encryption Std v2.0 (2016+2019).reg" *>&1 | Out-Null}
Start-Process -filepath "$env:windir\regedit.exe" -Argumentlist @("/s", "`"C:\Admin\_hA_Server_Build_Scripts\TLS Hardening\20230324 (Latest)\SCHANNEL hANZ Encryption Std v2.0 (2016+2019).reg`"")
Write-Host "Applied TLS Hardening" -ForegroundColor Green

#Apply Vulnerability Fixes
LogMessage "Applying Vulnerability Fixes"
#Invoke-Command {reg import "C:\Admin\_hA_Server_Build_Scripts\Vulnerability Fix\vulnerability_fix_2019.reg" *>&1 | Out-Null}
Start-Process -filepath "$env:windir\regedit.exe" -Argumentlist @("/s", "`"C:\Admin\_hA_Server_Build_Scripts\Vulnerability Fix\vulnerability_fix_2019.reg`"")
Write-Host "Applied Vulnerability Fixes" -ForegroundColor Green

#Set Runonce to Script4
Set-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name '!Script4' -Value "C:\Admin\_hA_Server_Build_Scripts\4.ServerBuildUpdates_T1Admin_v2023.06.25.cmd"

$EndDate = $(Get-Date -displayhint time)
LogMessage ""
LogMessage -LogLevel:2 "========================Script ended $EndDate====================="
LogMessage "============================================================================="

Write-Host "Script 3 completed now waiting 10 mins before rebooting server ...." -ForegroundColor Green
