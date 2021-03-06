function Get-FogAssociatedSnapins {
<#
    .SYNOPSIS
    Returns list of all snapins associated with a hostid
    
    .DESCRIPTION
    Gives a full list of all snapins associated with a given host
    Gets the current host's associated snapins if no hostid is given
    Finds the associated snapins by first getting all snapinassociations with all hosts and filters to ones with the hostid
    It then uses the snapinid of that filtering to get and add each snapin object to a list object

    .PARAMETER hostId
    The id of the host you want the assigned snapins to
    Defaults to getting the current hosts id with ((Get-FogHost).id)

    .EXAMPLE
    $assignedSnapins = Get-FogAssociatedSnapins
    $assignedSnapins | Where-Object name -match "office"

    Gets all the assigned snapins of the current host and then filters to any with the name office in them
    thus showing you what version of office you have assigned as a snapin to your host
#>
    
    [CmdletBinding()]
    param (
        $hostId=((Get-FogHost).id)
    )
    
    process {
        # $AllAssocs = (Invoke-FogApi -Method GET -uriPath snapinassociation).snapinassociations;
        $AllAssocs = (Get-FogObject -type object -coreObject snapinassociation).snapinassociations
        $snapins = New-Object System.Collections.Generic.List[object];
        # $allSnapins = Get-FogSnapins;
        $AllAssocs | Where-Object hostID -eq $hostID | ForEach-Object {
            $snapinID = $_.snapinID;
            $snapin = Get-FogObject -type object -coreObject snapin -IDofObject $snapinID;
            # $snapins.add((Invoke-FogApi -uriPath "snapin\$snapinID"))
            $snapins.add($snapin)

        }
        return $snapins;
    }
    
}