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
        $hostObject = (Get-FogHost)
    )
    
    begin {
        $macs = Get-FogMacAddresses;   
    }
    
    process {
        $hostMacs = $macs | Where-Object hostID -eq $hostObject.id
    }
    
    end {
        return $hostMacs;   
    }
}