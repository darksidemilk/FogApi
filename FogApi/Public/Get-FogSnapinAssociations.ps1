function Get-FogSnapinAssociations {
    <#
    .SYNOPSIS
    Helper function that returns a list of all snapin associations to any host on the server
    
    .DESCRIPTION
    Returns a list from the snapinassociations table. Each association has an id, hostid, and snapinid
    Not to be confused with Get-FogHostAssociatedSnapins which filters this list to a single hostid and then gets the snapin object for each association
    
    .EXAMPLE
    Get-FogSnapinAssociations

    Will return a full list of all snapin ids associated to host ids
    
    #>
    [CmdletBinding()]
    param (
        
    )
        
    process {
        $AllAssocs = (Get-FogObject -type object -coreObject snapinassociation).data
        return $AllAssocs
    }
    
}