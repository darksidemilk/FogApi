function Get-FogGroupAssociations {
    <#
    .SYNOPSIS
    Gets the group association objects that can be used to find group memberships
    
    .DESCRIPTION
    Returns the objects in the groupassociations table
    
    .EXAMPLE
    $groupAssocs = Get-FogGroupAssociations;
    $groupAssocs | ? hostId -eq ((Get-FogHost).id)
    
    Would give you the group associations of the current computer

    #>
    [CmdletBinding()]
    param ()
    
    process {
        $groupAssocs = (Get-FogObject -type object -coreObject groupassociation);
        return $groupAssocs.data;
    }
    
}