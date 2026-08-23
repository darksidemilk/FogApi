function Start-FogSnapins {
<#
    .SYNOPSIS
    Starts all associated snapins of a host

    .DESCRIPTION
    Starts the allsnapins task on a provided hostid

    .PARAMETER fogHost
    the foghost object to start the snapin task on, should be an object returned from get-foghost
    Can also be brought in via pipeline

    .PARAMETER hostid
    the hostid to start the task on

    .PARAMETER taskTypeid
    the id of the task to start, defaults to 12

    .PARAMETER TaskRequest
    A task request body, from New-FogTaskRequest or as a hashtable, used as the
    base for the task this queues. This cmdlet still sets deploySnapins itself;
    anything else the request carries is sent as given. An escape hatch for a
    field this cmdlet does not expose.
    .EXAMPLE
    Start-FogSnapins

    will get the current host's id and start all snapins on it

    .EXAMPLE
    Start-FogSnapins -hostid 42

    will start all snapins on the host with the id 42

    Expected output:
    { "id": 501, "success": true }

    .EXAMPLE
    Get-foghost -hostname 'MeowMachine' | Start-FogSnapins

    will get the host object for the host named 'MeowMachine' and start all snapins on it

    Expected output:
    { "id": 501, "success": true }

#>

    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline=$true,ParameterSetName='byObj')]
        $fogHost,
        [parameter(ParameterSetName='byid')]
        $hostid,
        $taskTypeid = '12',
        [FogTaskRequest]$TaskRequest
    )

    process {
        if ($null -ne $_) {
            $fogHost = $_;
            $hostid = $fogHost.id;
        } elseif ($null -eq $hostid) {
            $hostid = (Get-FogHost).id;
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
        $request = if ($PSBoundParameters.ContainsKey('TaskRequest')) { $TaskRequest } else { [FogTaskRequest]::new() }
        if ($null -eq $request.taskTypeID)    { $request.taskTypeID = $taskTypeid }
        if ($null -eq $request.deploySnapins) { $request.deploySnapins = -1 }
        $json = $request.ToJson();
        $result = New-FogObject -type objecttasktype -coreTaskObject host -jsonData $json -IDofObject $hostid;
        Write-Verbose "Snapin tasks have been queued on the server";
        return $result;
    }

}
