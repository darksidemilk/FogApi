function Get-FogMacAddresses {
    <#
    .SYNOPSIS
    Gets all mac addresses in fog
    
    .DESCRIPTION
    Returns all the objects in the macaddressassociations table which includes details on
    the mac address, the hostID connected to, if it's a primary, and if it's a pending mac
    
    .EXAMPLE
    $macs = Get-FogMacs

    Gets all the mac addresses in fog and puts them in the $macs object
    
    .NOTES
    Has an alias of Get-FogMacs but made the main name be MacAddresses to avoid confusion with apple mac computers
    #>
    [CmdletBinding()]
    [Alias('Get-FogMacs')]
    param ()
    
    
    process {
        $macs = Get-FogObject -type object -coreObject macaddressassociation | select-object -ExpandProperty macaddressassociations
        return $macs;
    }
    
}