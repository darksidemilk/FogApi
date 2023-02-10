function Get-FogHostGroup {
<#
    .SYNOPSIS
    returns the group objects that a host belongs to

    .DESCRIPTION
    requires the id of the host you want the groups that aren't the everyone group for

    .PARAMETER hostId
    The hostid to get the group memberships of

    .EXAMPLE
    Get-FogGroup -hostId ((Get-FogHost -hostname "computerName").id)

    Gets the fog group membership(s) of the fog host with the name computerName

#>
    [CmdletBinding()]
    [Alias('Get-FogGroup')]
    param (
        [int]$hostId
    )
    
    process {
        if (!$hostId) {
            $hostId = (Get-FogHost).id;
        }
        $hostGroups = (Get-FogObject -Type object -coreObject groupassociation).data
        $hostGroups = $hostGroups | Where-Object hostID -eq $hostId;
        $groups = New-Object System.Collections.Generic.list[system.object];

        if ($hostGroups) {
            $hostGroups.groupID | ForEach-Object {
                $group = Get-FogObject -type object -coreObject group -IDofObject $_
                $groups.add(($group))
            }
        } else {
            $groups = $Null;
        }
        return $groups;
    }

}
