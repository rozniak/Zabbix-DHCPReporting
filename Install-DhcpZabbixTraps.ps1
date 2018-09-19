<#
    .SYNOPSIS
    This script is used for installing the PowerShell scripts used for providing Zabbix
    traps into the task scheduler on the local machine.

    .DESCRIPTION
    This script first queries for the IP of the Zabbix Server or Proxy that is then
    embedded as part of the parameters used in the scheduled task actions. The tasks are
    scheduled to run hourly into order to provide data to Zabbix via traps.
    
    .EXAMPLE
    Install-DhcpZabbixTraps.ps1

    .NOTES
    Author: Rory Fewell
    GitHub: https://github.com/rozniak
    Website: https://oddmatics.uk
#>

Param (
    [Parameter(Position=0, Mandatory=$TRUE)]
    [ValidatePattern("^(\d+\.){3}\d+$")]
    [String]
    $ZabbixIP
)

$globalTrigger = New-ScheduledTaskTrigger -Daily -At 8am
$systemPrincipal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Set up content size scheduled task
#
$dhcpLeaseAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ('-NoProfile -NoLogo -File "' + $env:ProgramFiles + '\Zabbix Agent\DHCPREPORTS\Get-DhcpLeasesAvailable.ps1" -ZabbixIP ' + $ZabbixIP)

$dhcpLeaseTask = Register-ScheduledTask -TaskName "Calculate Available DHCP Leases (Zabbix Trap)" -Trigger $globalTrigger -Action $dhcpLeaseAction -Principal $systemPrincipal

$dhcpLeaseTask.Triggers[0].Repetition.Interval = "PT1H"
$dhcpLeaseTask | Set-ScheduledTask