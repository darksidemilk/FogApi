function Start-FogSnapin {
    <#
    .SYNOPSIS
    Starts a single snapin task for a given machine
    
    .DESCRIPTION
    Requires the hostID of the fog host and then either the name of the snapin or the id of the snapin to deploy
    
    .PARAMETER hostID
    The id of the host to deploy the task for
    
    .PARAMETER snapinname
    The name of the snapin to deploy
    
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
        [parameter(ParameterSetName='byName')]
        $snapinname,
        [parameter(ParameterSetName='byId')]
        $snapinId
    )
    
    
    process {
        $snapins = Get-FogSnapins;
        if  ($PSCmdlet.ParameterSetName -eq 'byName') {
            $snapin = $snapins | Where-Object name -eq $snapinname;
            $snapinId = $snapin.id
        } else {
            $snapin = $snapins | Where-Object id -eq $snapinId;
            $snapinname = $snapin.name
        }
        if ($null -eq $snapinId) {
            Write-Warning "No snapinid was found for the snapin $snapinName! not running any actions"
            return $null
        } else {
            $json = (@{
                "taskTypeID"='13';
                "deploySnapins"="$snapinId";
            } | ConvertTo-Json);
            $fogHost = Get-Foghost -hostID $hostID;
            "Deploying the snapin $snapinname to the host $($fogHost.name)" | out-host;
            New-FogObject -type objecttasktype -coreTaskObject host -jsonData $json -IDofObject "$hostID";
        }
    }
    
}