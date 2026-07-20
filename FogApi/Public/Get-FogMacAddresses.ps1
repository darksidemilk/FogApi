function Get-FogMacAddresses {
    <#
    .SYNOPSIS
    Gets all mac addresses in fog
    
    .DESCRIPTION
    Returns all the objects in the macaddressassociations table which includes details on
    the mac address, the hostID connected to, if it's a primary, and if it's a pending mac
    
    .EXAMPLE
    Get-FogMacs

    Gets all the mac addresses in fog

    Expected output:
    [ { "mac": "00:11:22:33:44:55" }, { "mac": "01:23:45:67:89:99" }, { "mac": "01:23:45:67:89:10" } ]

    .NOTES
    Has an alias of Get-FogMacs but made the main name be MacAddresses to avoid confusion with apple mac computers
    #>
    [CmdletBinding()]
    [Alias('Get-FogMacs')]
    param ()
    
    
    process {
        $macs = Get-FogObject -type object -coreObject macaddressassociation;
        return $macs.data;
    }
    
}