function Get-FogHostMacs {
    <#
    .SYNOPSIS
    Returns the macs assigned to a given host
    
    .DESCRIPTION
    Gets all macs and finds the ones with a matching hostid of the given object
    Use Get-FogHost to get the host object
    
    .PARAMETER hostObject
    The host object you get with Get-Foghost
    
    .EXAMPLE
    Get-MacsForHost (Get-FogHost)

    Will return the macs assigned to the computer running the command utilizing the alias Get-MacsForHost for this command

    .EXAMPLE
    Get-FogHostMacs -hostID 42

    Will return the macs assigned to the host with the id of 42

    Expected output:
    [ { "mac": "00:11:22:33:44:55" }, { "mac": "01:23:45:67:89:99" }, { "mac": "01:23:45:67:89:10" } ]

    #>
    [CmdletBinding()]
    [Alias('Get-MacsForHost')]
    param (
        [Parameter(ParameterSetName='byHostObject',ValueFromPipeline=$true)]
        $hostObject,
        [Parameter(ParameterSetName='byHostID')]
        $hostID
    )
    
    process {
        if ($null -ne $_) {
            $hostObject = $_;
            $hostID = $hostObject.id;
        }
        $hostID = Resolve-HostID $hostID
        if ($null -ne $hostID) {
            $macs = Get-FogMacAddresses;   
            $hostMacs = $macs | Where-Object hostID -eq $hostId
            return $hostMacs;   
        } else {
            Write-Error "invalid input!"
            return $null;
        }
    }
    
}