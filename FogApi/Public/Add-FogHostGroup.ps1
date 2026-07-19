function Add-FogHostGroup {
<#
    .SYNOPSIS
    Adds a host to a fog group

    .DESCRIPTION
    Creates a group association entry linking a host to a group, adding the host as a member of that group.
    Checks for an existing association first and skips creating a duplicate if the host is already a member of the group.

    .PARAMETER fogHost
    A fog host object (e.g. from Get-FogHost) to add to the group. Supports pipeline input.

    .PARAMETER hostID
    Can either be the id number of the host object or the name of the host in a string

    .PARAMETER groupID
    The id of the group to add the host to

    .EXAMPLE
    Add-FogHostGroup -hostID 42 -groupID 7

    Adds the host with id 42 to the group with id 7, returning the created group association

    Expected output:
    { "hostID": "42", "groupID": "7" }

    .EXAMPLE
    Get-FogHost -hostName MeowMachine | Add-FogHostGroup -groupID 7

    Finds the host by name and adds it to the group with id 7

    Expected output:
    { "hostID": "42", "groupID": "7" }

#>

    [CmdletBinding(DefaultParameterSetName='byHost')]
    [Alias('Add-FogGroupHost')]
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
            $existingAssoc = Get-FogGroupAssociations | Where-Object { ($_.hostID -eq $hostID) -and ($_.groupID -eq $groupID) }
            if ($null -ne $existingAssoc) {
                Write-Warning "Host $hostID is already a member of group $groupID"
                return $existingAssoc;
            } else {
                $newAssoc = @{
                    hostID  = "$hostID"
                    groupID = "$groupID"
                }
                return New-FogObject -type object -coreObject groupassociation -jsonData ($newAssoc | ConvertTo-Json)
            }
        } else {
            Write-Error "provided hostid was invalid!"
            return $null;
        }
    }

}
