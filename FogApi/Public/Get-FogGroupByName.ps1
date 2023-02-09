function Get-FogGroupByName {
    <#
    .SYNOPSIS
    Gets a fog group object by name
    
    .DESCRIPTION
    Searches the group objects for one that has a matching name of the given name
    
    .PARAMETER groupName
    The name of the group to search for
    
    .EXAMPLE
    $ITGroup = Get-FogGroupByName -groupName "IT"

    Will return the group object with a name that matches "IT";
    
    .NOTES
    Chose not to name this just get-foggroup as get-foggroup used to be a different function that got the group of a host
    Made that an alias of Get-FogHostGroup to avoid breaking anyones code
    #>
    [CmdletBinding()]
    param (
        $groupName
    )
    
    process {
        
        $group = (Find-FogObject -type search -coreobject group -stringToSearch $groupName);
        $group = $group.data | Where-Object name -match $groupName;
        return $group;      
    }
    
}