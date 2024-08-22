function Start-FogSnapin {
    <#
    .SYNOPSIS
    Starts a single snapin task for a given machine
    
    .DESCRIPTION
    Requires the hostID of the fog host and then either the name of the snapin or the id of the snapin to deploy
    
    .PARAMETER hostID
    The id of the host to deploy the task for
    
    .PARAMETER snapinname
    The name of the snapin to deploy or list of names
    
    .PARAMETER snapinId
    The id of the snapin to deploy
    
    .EXAMPLE
    Start-FogSnapin -hostID 1234 -snapinname 'office365'

    This will find the id of the snapin named 'office365' and deploy it on the host o id 1234
    The name of the host and the snapin will be output to the console before the task is started
    
    .EXAMPLE
    Start-FogSnapin -hostID 1234 -snapinid 12

    This will deploy a single snapin task for the snapin of id 12 for host 1234
    The name of the host and the snapin will be output to the console before the task is started

    #>
    [CmdletBinding(DefaultParameterSetName='byId')]
    param (
        [parameter(ParameterSetName='byId')]
        [parameter(ParameterSetName='byName')]
        $hostID,
        [parameter(ValueFromPipeline=$true,ParameterSetName='byId-byobj')]
        [parameter(ValueFromPipeline=$true,ParameterSetName='byName-byobj')]
        $fogHost,
        [parameter(ParameterSetName='byName')]
        [parameter(ParameterSetName='byName-byobj')]
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
        [string[]]$snapinname,
        [parameter(ParameterSetName='byId')]
        [parameter(ParameterSetName='byId-byobj')]
        [string[]]$snapinId
    )
    
    
    process {
        if ($null -ne $_) {
            $fogHost = $_;
            $hostID = $fogHost.id;
        }
        $snapins = Get-FogSnapins;
        if  (($PSCmdlet.ParameterSetName -eq 'byName') -OR ($PSCmdlet.ParameterSetName -eq 'byName-byObj')) {
            # $snapin = "$((($snapins | Where-Object name -eq "$($_)")))";
            $snapinIDs = New-Object System.Collections.Generic.List[Object];

            $snapinname | ForEach-Object {
                $snapinIds.add(("$((($snapins | Where-Object name -eq "$($_)").id))"))
            }
            # $snapinId = $snapinIDs -join ","
            # "$snapinID" | out-host;
            # $snapinname = $snapinname
        } else {
            # $snapinID | ForEach-Object {
            # }
            $snapin = $snapins | Where-Object id -in $snapinId;
            $snapinname = $snapin.name
        }
        if (($null -eq $snapinId) -and ($null -eq $snapinIDs)) {
            Write-Warning "No snapinid was found for the snapin $snapinName! not running any actions"
            return $null
        } else {
            if ($null -ne $snapinIDs) {
                $snapinID = $snapinIDs
            }
            $results = New-Object System.Collections.Generic.List[Object];
            $snapinId | ForEach-Object {
                $json = (@{
                    "taskTypeID"='13';
                    "deploySnapins"="$_";
                } | ConvertTo-Json);
                if ($null -eq $fogHost) {
                    $fogHost = Get-Foghost -hostID $hostID;
                }
                $snapinname = ($snapins | Where-Object id -in $_).name
                "Deploying the snapin $snapinname to the host $($fogHost.name)" | out-host;
                $result = New-FogObject -type objecttasktype -coreTaskObject host -jsonData $json -IDofObject "$hostID";
                $results.add(($result));
            }
            return $results;
        }
    }
    
}