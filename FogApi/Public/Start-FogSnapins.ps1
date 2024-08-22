function Start-FogSnapins {
<#
    .SYNOPSIS
    Starts all associated snapins of a host

    .DESCRIPTION
    Starts the allsnapins task on a provided hostid

    .PARAMETER hostid
    the hostid to start the task on

    .PARAMETER taskTypeid
    the id of the task to start, defaults to 12

    .EXAMPLE
    Start-FogSnapins

    will get the current hosts id and start all snapins on it
#>

    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline=$true,ParameterSetName='byObj')]
        $fogHost,
        [parameter(ParameterSetName='byid')]
        $hostid = ((Get-FogHost).id),
        $taskTypeid = '12'
    )
    
    process {
        if ($null -ne $_) {
            $fogHost = $_;
            $hostid = $fogHost.id;
        }
        Write-Verbose "Stopping any queued snapin tasks";
        try {
            $tasks = Get-FogActiveTasks;
        } catch {
            $tasks = (Invoke-FogApi -Method GET -uriPath "task/active").tasks;
        }
        $tasks = $tasks | Where-Object { $_.type.id -match $taskTypeid} #filter task list to all snapins task.
        $taskID = (($tasks | Where-Object hostID -match $hostid).id);
        if ($null -ne $taskID) { #if active snapin tasks are found for the host cancel them, otherwise do nothing to tasks
            Write-Verbose "Found $($taskID.count) tasks deleting them now";
            $taskID | ForEach-Object{
                try {
                    Remove-FogObject -type objecttasktype -coreTaskObject task -IDofObject $_;
                } catch {
                    Invoke-FogApi -Method DELETE -uriPath "task/$_/cancel";
                }
            }
        }
        # $snapAssocs = Invoke-FogApi -uriPath snapinassociation -Method Get;
        # $snaps = $snapAssocs.snapinassociations | ? hostid -eq $hostid;
        Write-Verbose "starting all snapin task for host";
        $json = (@{
            "taskTypeID"=$taskTypeid;
            "deploySnapins"=-1;
        } | ConvertTo-Json);
        $result = New-FogObject -type objecttasktype -coreTaskObject host -jsonData $json -IDofObject $hostid;
        Write-Verbose "Snapin tasks have been queued on the server";
        return $result;
    }

}
