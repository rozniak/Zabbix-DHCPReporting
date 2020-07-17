<#
    .SYNOPSIS
    This script is used for removing the PowerShell scripts used for providing Zabbix
    traps into the task scheduler on the local machine.

    .DESCRIPTION
    This script will uninstall all scheduled tasks found with the GUID of the DHCP
    Zabbix trap tasks in their description.
    
    .EXAMPLE
    Uninstall-DhcpZabbixTraps.ps1

    .NOTES
    Author: Rory Fewell
    GitHub: https://github.com/rozniak
    Website: https://oddmatics.uk
#>

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

$guid = Get-Content -Path "$scriptRoot\task-guid"

Get-ScheduledTask | Where-Object { $_.Description -eq $guid } | Unregister-ScheduledTask -Confirm:$FALSE
