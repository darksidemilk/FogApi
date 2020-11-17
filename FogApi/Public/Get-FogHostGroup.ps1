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
 
    begin {
        [bool]$found = $false;
        Write-Verbose 'Getting all fog group associations...';
        # $groupAssocs = (Invoke-FogApi -uriPath groupassociation).groupassociations;
        $groupAssocs = Get-FogGroupAssociations;

        Write-Verbose 'Getting all fog groups...';
        $groups = Get-FogGroups;

    }

    process {
        $hostGroups = $groupAssocs | Where-Object hostID -eq $hostId;
       
        $found = $true;
        $group = $groups | Where-Object id -eq $hostGroups.groupID;

        $group = $hostGroups;
        
    }

    end {
        if($found){
            return $group;
        }
        return $found;
    }

}
