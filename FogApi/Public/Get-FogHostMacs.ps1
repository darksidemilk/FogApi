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

    Will return the macs assigned to the computer running the command
    
    #>
    [CmdletBinding()]
    [Alias('Get-MacsForHost')]
    param (
        [Parameter(ParameterSetName='byHostObject')]
        $hostObject = (Get-FogHost),
        [Parameter(ParameterSetName='byHostID')]
        $hostID
    )
    
    process {
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