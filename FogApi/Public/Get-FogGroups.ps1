function Get-FogGroups {
    <#
    .SYNOPSIS
    Returns all fog groups
    
    .DESCRIPTION
    Gets all the fog groups and returns them in an object
    
    .EXAMPLE
    $groups = Get-FogGroups
    
    .NOTES
    A group object does not contain membership information, you need to filter groupassociations to find membership
    but this will give you the id of the group to search for within that object, you'll also need the host id to find all associations of a host
    #>
    [CmdletBinding()]
    param ()
    
    
    process {
        $groups = (Get-FogObject -type object -coreobject group).groups;
        return $groups;
    }
    
}