function Get-FogGroupAssociations {
    <#
    .SYNOPSIS
    Gets the group association objects that can be used to find group memberships
    
    .DESCRIPTION
    Returns the objects in the groupassociations table
    
    .EXAMPLE
    Get-FogGroupAssociations | ? hostId -eq ((Get-FogHost).id)
    
    Would give you the group associations filtered to the current computer

    .EXAMPLE
    Get-FogGroupAssociations;

    This will return all group association objects in the fog database

    #>
    [CmdletBinding()]
    param ()
    
    process {
        $groupAssocs = (Get-FogObject -type object -coreObject groupassociation);
        return $groupAssocs.data;
    }
    
}