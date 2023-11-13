# Updated: Willie Cornett
# Date: 25/06/2023

#Log Levels 1 Error, 2 Debug, 3 Info
param([bool] $logToFile = 1, [Int32] $CurrentLogLevel = 3)

$ScriptName = Split-Path $PSCommandPath -Leaf

$LogFile = "$PSScriptRoot\1.ServerPostBuildUpdates_v2023.06.25.log"
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


Function GetOSversion{
param 
(
[string]$ComputerName
	)

# Get OS vrsion 

$sOS =Get-WmiObject -class Win32_OperatingSystem -computername $ComputerName




# Get Architecture

$sOS1 =Get-WmiObject -class win32_processor -computername $ComputerName  


        
$OSArch = $sOS1.AddressWidth

    if ($OSArch -eq '64') {$OSenv='x64'}
       
    if ($OSArch -eq '32') {$OSenv='x86'}
    
     if (!$OSArch)
     {$OSenv='????'
     LogMessage "OS Architecture not found on remote computer $ComputerName"
     }
      
# Updated new OS types   
      
If (($sOS.Caption).Contains("2003"))  {$OS='W2k3'}      
       
If (($sOS.Caption).Contains("2008")) {$OS='W2k8'}

If (($sOS.Caption).Contains("2008 R2")) {$OS='W2k8R2'}
        
If (($sOS.Caption).Contains("2012")) {$OS='W2k12'}
        
If (($sOS.Caption).Contains("2012 R2")) {$OS='W2k12R2'}       

If (($sOS.Caption).Contains("2016")) {$OS='W2k16'} 

If (($sOS.Caption).Contains("2019")) {$OS='W2k19'} 
    
    
    LogMessage " Server:    $ComputerName  OS:   $OS  Environment Architecture:      $OSenv"
    write-host " Server:    $ComputerName  OS:   $OS  Environment Architecture:      $OSenv" -ForegroundColor Yellow
    write-host " ====================================================================================" -ForegroundColor Yellow
    
    return, $OSenv,$OS
    
}

                 

Function changeComputerDescription{
Write-host "Adding server Description" -ForegroundColor Cyan
        LogMessage "Adding server Description"

Try{

$Computervalue=Get-WmiObject -class Win32_OperatingSystem -ComputerName $env:COMPUTERNAME
#$DiscriptionText=Read-Host "Enter Server Descriptiopn"
$DiscriptionText=$file.ServerDescription
$Computervalue.Description= $DiscriptionText
$Computervalue.put()
Write-host "Successfully added server Description" -ForegroundColor Green
        LogMessage "Successfully added server Description"

}
Catch {Write-host "Failed to add server Description" -ForegroundColor Red
        LogMessage "Failed to add server Description"}
}


Function changeComputerName{
Write-host "Renaming server computername" -ForegroundColor Cyan
        LogMessage "Renaming server computername"

Try{

#$Computervalue=Get-WmiObject -class Win32_OperatingSystem -ComputerName $env:COMPUTERNAME
#$NewServername=Read-Host "Enter New VM Server Name "
$NewServername=$file.ServerName

if ($NewServername -ne $server) {Rename-Computer -NewName $NewServername -Force}

Write-host "Successfully changed Computer Name - restart required for changes to take effect" -ForegroundColor Green
        LogMessage "Successfully changed Computer Name - restart required for changes to take effect"

}
Catch {Write-host "Failed to change comuptername" -ForegroundColor Red
        LogMessage "Failed to change computername"}
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

						

						
                           $PPP2= GetOSversion -ComputerName $server

                           $OSs=$PPP2[1]
                           $OSenvs=$PPP2[0]

                           
                           
                           $OSenvs="x64"

                           

                           
      
     
             
             
           # Applying settings to any type of Windows OS

           
            changeComputerName

            changeComputerDescription
                                                                                    
					}

#Update CDROM drive letter from D: to Z:
LogMessage "Updating CDROM drive from D: to Z:"
$drv = Get-WmiObject win32_volume | Where { $_.drivetype -eq '5'}
$drv.DriveLetter = "Z:"
$drv.Put() | out-null
Write-Host "Successfully changed CDROM from D: to Z:" -ForegroundColor Green

#Extend C: drive OS Partition to Max Size
LogMessage "Extending C: drive disk"
Resize-Partition -DriveLetter C -Size $(Get-PartitionSupportedSize -DriveLetter C).SizeMax
Write-Host "Successfully expanded C: drive ...." -ForegroundColor Green

#Format any blanks disks to Max Size
LogMessage "Formating new disks"
Get-Disk | where PartitionStyle -EQ 'RAW' | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DATA" -confirm:$false
Write-Host "Successfully formatted new disks ...." -ForegroundColor Green

#Setup Static IP address on NIC
LogMessage "Configure Static IP on network card"
#$IP = Read-Host -Prompt 'Enter IP Address eg. 10.136.0.199'
$IP = $file.ServerIPAddress
	$MaskBits = 24 # This means subnet mask = 255.255.255.0
    $IPByte = $IP.Split(".")
    $Gateway = ($IPByte[0]+"."+$IPByte[1]+"."+$IPByte[2]+".1")
	$DNS1 = $file.ServerDNS1
	$DNS2 = $file.ServerDNS2
    $DNS3 = $file.ServerDNS3
	#$DNS1 = "10.136.0.11"
	#$DNS2 = "10.136.0.12"
    #$DNS3 = "10.140.0.11"
	$IPType = "IPv4"
	# Retrieve the network adapter that you want to configure
	$adapter = Get-NetAdapter | ? {$_.Status -eq "up"}
	# Remove any existing IP, gateway from our ipv4 adapter
	If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
	 $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
	}
	If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
	 $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
	}
	 # Configure the IP address and default gateway
	$adapter | New-NetIPAddress `
	 -AddressFamily $IPType `
	 -IPAddress $IP `
	 -PrefixLength $MaskBits `
	 -DefaultGateway $Gateway
	# Configure the DNS client server IP addresses
	$adapter | Set-DnsClientServerAddress -ServerAddresses $DNS1,$DNS2,$DNS3
Write-Host "Successfully configured Static IP Address ...." -ForegroundColor Green

#Rename Network Adapter to VLAN Tag
LogMessage "Renaming NIC to VLAN"
Get-NetAdapter | Rename-NetAdapter -NewName $file.ServerVLAN
Write-Host "Successfully renamed NIC to " $file.ServerVLAN -ForegroundColor Green

#Disable NetBios on Network Adapter
LogMessage "Disabling NetBios"
$base = "HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"
$interfaces = Get-ChildItem $base | Select -ExpandProperty PSChildName
foreach($interface in $interfaces) {
    Set-ItemProperty -Path "$base\$interface" -Name "NetbiosOptions" -Value 2
}
Write-Host "Successfully disabled NetBios on NIC ...." -ForegroundColor Green   

#Update TimeZone
LogMessage "Updating Time Zone to New Zealand Standard Time"
Set-TimeZone -Id "New Zealand Standard Time"
Write-Host "Successfully updated Time Zone ...." -ForegroundColor Green
   

#Set Page File to Standard static setting
LogMessage "Setting Page File to Static"
cd C:\Admin\_hA_Server_Build_Scripts
.\Set_pagefile.ps1
Write-Host "Successfully updated Page File ...." -ForegroundColor Green

#Set Runonce to Script2
Set-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name '!Script2' -Value "C:\Admin\_hA_Server_Build_Scripts\2.ServerJoinDomain_v2023.06.25.cmd"

#Setup Autologon for CCL to run scripts 2, 3
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon" /v AutoAdminLogon /d 1  /f
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon" /v AutoLogonCount /t REG_DWORD /d 2  /f
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon" /v DefaultUserName /d CCL  /f
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon" /v DefaultPassWord /d M0nday2023 /f

#Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"

Write-Host "Script 1 completed now rebooting server ...." -ForegroundColor Green

$EndDate = $(Get-Date -displayhint time)
LogMessage ""
LogMessage -LogLevel:2 "========================Script ended $EndDate====================="
LogMessage "============================================================================="