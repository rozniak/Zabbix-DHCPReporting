<#
    .SYNOPSIS
    This script is used for obtaining the number of available DHCP leases on the
    server.

    .DESCRIPTION
    This script retrieves the first scope discovered via the Get-DhcpServerv4Scope
    cmdlet, and calculates the available leases based on the range and count of
    existing leases.

    .PARAMETER ZabbixIP
    The IP address of the Zabbix server/proxy to send the value to.
    
    .EXAMPLE
    Get-DhcpLeasesAvailable.ps1 -ZabbixIP 10.0.0.240

    .NOTES
    Author: Rory Fewell
    GitHub: https://github.com/rozniak
    Website: https://oddmatics.uk
#>

Param (
    [Parameter(Position=0,Mandatory=$TRUE)]
    [ValidatePattern("^(\d+\.){3}\d+$")]
    [String]
    $ZabbixIP
)

Function Swap-Endian
{
    Param(
        [Parameter(Mandatory=$TRUE)]
        $LittleValue
    )

    $bytes = [System.BitConverter]::GetBytes($LittleValue);
    $bytes = [System.Linq.Enumerable]::Take($bytes, 4);
    $bytes = [System.Linq.Enumerable]::Reverse($bytes);

    return [System.BitConverter]::ToUInt32($bytes, 0);
}


$dhcpScope = (Get-DhcpServerv4Scope)[0];

$addressSpace = (Swap-Endian -LittleValue $dhcpScope.EndRange.Address) -
                (Swap-Endian -LittleValue $dhcpScope.StartRange.Address);
$leaseCount = (Get-DhcpServerv4Lease -ScopeId $dhcpScope.ScopeId.ToString()).Length;
$addressesRemaining = $addressSpace - $leaseCount;

# Push value to Zabbix
#
& ($env:ProgramFiles + "\Zabbix Agent\bin\win64\zabbix_sender.exe") ("-z", $ZabbixIP, "-p", "10051", "-s", $env:ComputerName, "-k", "dhcp.freeleases", "-o", $addressesRemaining)