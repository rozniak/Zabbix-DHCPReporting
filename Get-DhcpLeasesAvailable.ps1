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
    
    .PARAMETER ComputerName
    The hostname that should be reported to Zabbix, in case the hostname you set up in
    Zabbix isn't exactly the same as this computer's name.
    
    .EXAMPLE
    Get-DhcpLeasesAvailable.ps1 -ZabbixIP 10.0.0.240

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

$addressSpace    = (Swap-Endian -LittleValue $dhcpScope.EndRange.Address) -
                   (Swap-Endian -LittleValue $dhcpScope.StartRange.Address);
$leaseCount      = (Get-DhcpServerv4Lease -ScopeId $dhcpScope.ScopeId).Length;
$leasesRemaining = $addressSpace - $leaseCount;

# Push value to Zabbix
#
$zabbixArgs =
    (
        "-z",
        $ZabbixIP,
        "-p",
        "10051",
        "-s",
        $ComputerName,
        "-k",
        "dhcp.freeleases",
        "-o",
        $leasesRemaining
    );
$zabbixSender = Get-ChildItem -Path   ($env:ProgramFiles + "\Zabbix Agent") `
                              -Filter "zabbix_sender.exe"                   `
                              -Recurse;

& $zabbixSender.FullName $zabbixArgs;
