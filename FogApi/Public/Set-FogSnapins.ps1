function Set-FogSnapins {
<#
.SYNOPSIS
Sets a list of snapins to a host, appends to existing ones

.DESCRIPTION
Goes through a provided list variable and adds each matching snapin to the provided
hostid

.PARAMETER hostID
The id of a host to set snapins on, defaults to finding if of current computer if none is given

.PARAMETER pkgList
String array list of snapins to add to the host

.PARAMETER exactNames
switch param to indicate matching to exact snapin names instead of matching the name. Useful if you have things like office and office-64 that both match to 'office'

.EXAMPLE
Set-FogSnapins -hostid (Get-FogHost).id -pkgList @('Office365','chrome','slack')

This would associate snapins that match the titles of office365, chrome, and slack to the provided host id
they could then be deployed with start-fogsnapins

#>

    [CmdletBinding()]
    [Alias('Add-FogSnapins')]
    param (
        $hostid = ((Get-FogHost).id),
        $pkgList,
        [switch]$exactNames
    )

    process {
        Write-Verbose "Association snapins from package list with host";
        $snapins = Get-FogSnapins;
        # $urlPath = "snapinassociation/create"
        $curSnapins = Get-FogAssociatedSnapins -hostId $hostid;
        $result = New-Object System.Collections.Generic.List[Object];
        if ($null -ne $pkgList) {
            $pkgList | ForEach-Object {
                if ($exactNames) {
                    $json = @{
                        snapinID = "$((($snapins | Where-Object name -eq "$($_)").id))";
                        hostID = "$hostid"
                    };
                } else {
                    $json = @{
                        snapinID = "$((($snapins | Where-Object name -match "$($_)").id))";
                        hostID = "$hostid"
                    };
                }
                Write-Verbose "$_ is pkg snapin id found is $($json.snapinID)";
                if (($null -ne $json.SnapinID) -AND ($json.SnapinID -notin $curSnapins.id)) {
                    $json = $json | ConvertTo-Json;
                    $result.add((New-FogObject -type object -coreObject snapinassociation -jsonData $json));
                } elseif ($json.SnapinID -in $curSnapins.id) {
                    Write-Warning "$_ snapin of id $($json.SnapinID) is already associated with this host";
                } else {
                    Write-Warning "no snapin ID found for $_ pkg";
                }
                # Invoke-FogApi -Method POST -uriPath $urlPath -jsonData $json;
            }
        }
        return $result;
    }


}
