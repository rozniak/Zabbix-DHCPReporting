<#
    .SYNOPSIS
    This script is used for installing the PowerShell scripts used for providing Zabbix
    traps into the task scheduler on the local machine.

    .DESCRIPTION
    This script first queries for the IP of the Zabbix Server or Proxy that is then
    embedded as part of the parameters used in the scheduled task actions. The tasks are
    scheduled to run hourly into order to provide data to Zabbix via traps.
    
    .PARAMETER ZabbixIP
    The IP address of the Zabbix server/proxy to send the value to.
    
    .PARAMETER ComputerName
    The hostname that should be reported to Zabbix, in case the hostname you set up in
    Zabbix isn't exactly the same as this computer's name.
    
    .EXAMPLE
    Install-DhcpZabbixTraps.ps1 -ZabbixIP 10.0.0.240

    .NOTES
    Author: Rory Fewell
    GitHub: https://github.com/rozniak
    Website: https://oddmatics.uk
#>

Param (
    [Parameter(Position=0, Mandatory=$TRUE)]
    [ValidatePattern("^(\d+\.){3}\d+$")]
    [String]
    $ZabbixIP,
    [Parameter(Position=1, Mandatory=$FALSE)]
    [ValidatePattern(".+")]
    [String]
    $ComputerName = $env:COMPUTERNAME
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition;

$globalTrigger   = New-ScheduledTaskTrigger -Daily -At 8am
$guid            = Get-Content -Path "$scriptRoot\task-guid"
$systemPrincipal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Set up content size scheduled task
#
$dhcpLeaseAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ('-NoProfile -NoLogo -File "' + $env:ProgramFiles + '\Zabbix Agent\DHCPREPORTS\Get-DhcpLeasesAvailable.ps1" -ZabbixIP ' + $ZabbixIP + ' -ComputerName ' + $ComputerName)

$dhcpLeaseTask = Register-ScheduledTask -TaskName "Calculate Available DHCP Leases (Zabbix Trap)" -Trigger $globalTrigger -Action $dhcpLeaseAction -Principal $systemPrincipal -Description $guid

$dhcpLeaseTask.Triggers[0].Repetition.Interval = "PT1H"
$dhcpLeaseTask | Set-ScheduledTask
