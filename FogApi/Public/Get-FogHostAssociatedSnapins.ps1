function Get-FogHostAssociatedSnapins {
<#
    .SYNOPSIS
    Returns list of all snapins associated with a given hostid, defaults to current host if no hostid is given
    
    .DESCRIPTION
    Gives a full list of all snapins associated with a given host
    Gets the current host's associated snapins if no hostid is given
    Finds the associated snapins by first getting all snapinassociations with all hosts and filters to ones with the hostid
    It then uses the snapinid of that filtering to get and add each snapin object to a list object
    If it finds a snapin association with a snapinID of '0' that one will be skipped in the return and a warning will be displayed telling you to run Repair-FogSnapinAssociations

    .PARAMETER hostId
    The id of the host you want the assigned snapins to
    Defaults to getting the current hosts id with ((Get-FogHost).id)

    .EXAMPLE
    $assignedSnapins = Get-FogAssociatedSnapins; $assignedSnapins | Where-Object name -match "office"

    Gets all the assigned snapins of the current host and then filters to any with the name office in them
    thus showing you what version of office you have assigned as a snapin to your host
#>
    
    [CmdletBinding()]
    [Alias('Get-FogAssociatedSnapins','Get-FogHostSnapins','Get-FogHostSnapinAssociations')]
    param (
        $hostId=((Get-FogHost).id)
    )
    
    process {
        # $AllAssocs = (Invoke-FogApi -Method GET -uriPath snapinassociation).snapinassociations;
        $AllAssocs = Get-FogSnapinAssociations
        $snapins = New-Object System.Collections.Generic.List[object];
        # $allSnapins = Get-FogSnapins;
        
        $AllAssocs | Where-Object hostID -eq $hostID | ForEach-Object {
            $snapinID = $_.snapinID;
            if ($snapinID -ne 0) {
                $snapin = Get-FogObject -type object -coreObject snapin -IDofObject $snapinID;
            } else {
                Write-Warning "A snapin associated to a no longer existing or invalid snapin exists for this host! Run Repair-SnapinAssociations to fix for the server!"
            }
            # $snapins.add((Invoke-FogApi -uriPath "snapin\$snapinID"))
            $snapins.add($snapin)

        }
        return $snapins;
    }
    
}