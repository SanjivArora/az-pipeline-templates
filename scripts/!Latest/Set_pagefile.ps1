# Get memory value
$RAM = (Get-CimInstance Win32_PhysicalMemory | Measure-OBject -Property capacity -Sum).sum /1mb
# Disable System Managed and Auto Managed Pagefile Size
$computerSystem = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges
    $computerSystem.AutomaticManagedPagefile = $false
    $computerSystem.Put()|Out-Null
$pageFileSetting = Get-WmiObject -Class Win32_PageFileSetting
# Set PageFile equal to 1xRAM + 257MB for memory larger then 6GB
if ($RAM -gt 6144)
{  
    $PAGESIZE = $RAM + 257    
}
else
# Set PageFile equal to 6144 MB (6GB) + 257MB for all memory smaller or equal to 6GB
{
    $PAGESIZE = 6401
}
$pageFileSetting.InitialSize = $PAGESIZE
$pageFileSetting.MaximumSize = $PAGESIZE

$pageFileSetting.Put()|Out-Null

(get-wmiobject win32_pagefile) | select-object name, initialsize, maximumsize, filesize
