function Remove-FogHostGroup {
<#
    .SYNOPSIS
    Removes a host from a fog group

    .DESCRIPTION
    Finds the group association entry linking a host to a group and deletes it, removing the host from that group's membership.

    .PARAMETER fogHost
    A fog host object (e.g. from Get-FogHost) to remove from the group. Supports pipeline input.

    .PARAMETER hostID
    Can either be the id number of the host object or the name of the host in a string

    .PARAMETER groupID
    The id of the group to remove the host from

    .EXAMPLE
    Remove-FogHostGroup -hostID 42 -groupID 3

    Removes the host with id 42 from the group with id 3.
    A successful delete returns an empty response from the fog server.

    Expected output:
    ""

    .EXAMPLE
    Get-FogHost -hostName MeowMachine | Remove-FogHostGroup -groupID 5

    Finds the host by name and removes it from the group with id 5.
    A successful delete returns an empty response from the fog server.

    Expected output:
    ""

#>

    [CmdletBinding(DefaultParameterSetName='byHost')]
    [Alias('Remove-FogGroupHost')]
    param (
        [parameter(ValueFromPipeline=$true,ParameterSetName='byHost')]
        $fogHost,
        [parameter(ParameterSetName='byId')]
        $hostID,
        [parameter(Mandatory=$true,ParameterSetName='byHost')]
        [parameter(Mandatory=$true,ParameterSetName='byId')]
        $groupID
    )

    process {
        if ($null -ne $_) {
            $fogHost = $_;
            $hostID = $fogHost.id;
        }
        $hostID = Resolve-HostID $hostID
        if ($null -ne $hostID) {
            $assoc = Get-FogGroupAssociations | Where-Object { ($_.hostID -eq $hostID) -and ($_.groupID -eq $groupID) }
            if ($null -eq $assoc) {
                Write-Warning "Host $hostID is not a member of group $groupID, nothing to remove"
                return $null;
            } else {
                return Remove-FogObject -type object -coreObject groupassociation -IDofObject $assoc.id;
            }
        } else {
            Write-Error "provided hostid was invalid!"
            return $null;
        }
    }

}
