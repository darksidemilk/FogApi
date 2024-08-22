function Set-FogSnapins {
<#
.SYNOPSIS
Sets a list of snapins to a host, appends to existing ones

.DESCRIPTION
Goes through a provided list variable and adds each matching snapin to the provided hostid
Performs validation on the input before 

.PARAMETER hostID
The id of a host to set snapins on, defaults to finding if of current computer if none is given

.PARAMETER pkgList
String array list of snapins to add to the host, supports tab completion.

.PARAMETER exactNames
switch param to indicate matching to exact snapin names instead of matching the name. Useful if you have things like office and office-64 that both match to 'office'

.PARAMETER repairBeforeAdd
Switch param to run Repair-FogSnapinAssociations before attempting to add new snapin associations, useful if you're getting 404 errors

.EXAMPLE
Set-FogSnapins -hostid (Get-FogHost).id -pkgList @('Office365','chrome','slack')

This would associate snapins that match the titles of office365, chrome, and slack to the provided host id
they could then be deployed with start-fogsnapins

#>

    [CmdletBinding()]
    [Alias('Add-FogSnapins')]
    param (
        [parameter(ValueFromPipeline=$true,ParameterSetName='byObject')]
        $hostObj,
        [parameter(ParameterSetName='byId')]
        $hostid = ((Get-FogHost).id),
        [parameter(ParameterSetName='byId')]
        [parameter(ParameterSetName='byObject')]
        [ArgumentCompleter({
            param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
            # if(Test-FogVerAbove1dot6) {
            $r = (Get-FogSnapins)

            if ($WordToComplete) {
                $r.Where.Name{ $_ -match "^$WordToComplete" }
            }
            else {
                $r.Name
            }
            # }
        })]
        [string]$pkgList,
        [parameter(ParameterSetName='byId')]
        [parameter(ParameterSetName='byObject')]
        [switch]$exactNames,
        [parameter(ParameterSetName='byId')]
        [parameter(ParameterSetName='byObject')]
        [switch]$repairBeforeAdd
    )

    process {
        if ($null -ne $_) {
            $hostObj = $_;
        }
        if ($null -ne $hostObj) {
            $hostid = $hostObj.id;
        }
        Write-Verbose "Association snapins from package list with host";
        if ($repairBeforeAdd) {
            try {
                Repair-FogSnapinAssociations -ea stop;
            } catch {
                Write-Warning "There was an issue running the repair command, still continuing to attempt to add new snapin associations"
            }
        }
        $snapins = Get-FogSnapins;

        # $urlPath = "snapinassociation/create"
        $curSnapins = Get-FogHostAssociatedSnapins -hostId $hostid;
        $results = New-Object System.Collections.Generic.List[Object];
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
                if (($null -ne $json.SnapinID) -AND ($json.SnapinID -notin $curSnapins.id) -AND ($json.snapinID -ge "0")) {
                    $json = $json | ConvertTo-Json;
                    try {
                        $result = New-FogObject -type object -coreObject snapinassociation -jsonData $json -ea stop
                        $results.add($result);
                    } catch {
                        Write-Warning "Error adding snapin for $($_)!`npassed json was $($json)"
                    }
                } elseif ($json.SnapinID -in $curSnapins.id) {
                    Write-Warning "$_ snapin of id $($json.SnapinID) is already associated with this host";
                } else {
                    Write-Warning "no snapin ID found for $_ pkg";
                }
                # Invoke-FogApi -Method POST -uriPath $urlPath -jsonData $json;
            }
        }
        return $results;
    }


}
