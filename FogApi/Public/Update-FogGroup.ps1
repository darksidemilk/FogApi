function Update-FogGroup {
<#
    .SYNOPSIS
    Updates a fog group's own fields

    .DESCRIPTION
    Edits the group object itself (e.g. name, description) rather than its host membership.
    Use Add-FogHostGroup/Remove-FogHostGroup to manage which hosts belong to a group.

    .PARAMETER groupObj
    A fog group object (e.g. from Get-FogGroups) to update. Supports pipeline input.

    .PARAMETER groupID
    The id of the group to update

    .PARAMETER settings
    A hashtable of the group fields to change, e.g. @{name="NewName"; description="New description"}

    .EXAMPLE
    Update-FogGroup -groupID 5 -settings @{description="Lab computers"}

    Updates the description field of the group with id 5

    .EXAMPLE
    Get-FogGroupByName "Lab" | Update-FogGroup -settings @{name="Lab Computers"}

    Finds the group named "Lab" and renames it to "Lab Computers"

#>

    [CmdletBinding(DefaultParameterSetName='byId')]
    [Alias('Set-FogGroup')]
    param (
        [parameter(ValueFromPipeline=$true,ParameterSetName='byObj')]
        $groupObj,
        [parameter(Mandatory=$true,ParameterSetName='byId')]
        $groupID,
        [parameter(Mandatory=$true,ParameterSetName='byObj')]
        [parameter(Mandatory=$true,ParameterSetName='byId')]
        [hashtable]$settings
    )

    process {
        if ($null -ne $_) {
            $groupObj = $_;
        }
        if ($null -ne $groupObj) {
            $groupID = $groupObj.id;
        }
        $jsonData = ($settings | ConvertTo-Json);
        return Update-FogObject -type object -coreObject group -IDofObject $groupID -jsonData $jsonData
    }

}
