function Start-FogSnapins {
    <#
        .SYNOPSIS
        Starts all associated snapins of a host
    
        .DESCRIPTION
        Starts the allsnapins task on a provided hostid
    
        .PARAMETER hostid
        the hostid to start the task on
    
        .PARAMETER snapinIDs
        list of snapinIDs to deploy
    
        .EXAMPLE
        Start-FogSnapins
    
        will get the current hosts id and start all snapins currently associated with it
    #>
    
        [CmdletBinding()]
        [Alias('Start-FogSnapin')]
        param (
            [Parameter(ParameterSetName='AllSnapins')]
            [Parameter(ParameterSetName='SingleSnapin')]
            $hostid = ((Get-FogHost).id),
            [Parameter(ParameterSetName='SingleSnapin')]
            [string[]]$snapinIDs
        )
    
        begin {
            if ($PSCmdlet.ParameterSetName -eq 'AllSnapins') {
                $snapinIDs = '-1'
                $taskTypeid = '12'
            } else {
                $taskTypeid = '13'
            }
            Write-Verbose "Stopping any queued snapin tasks";
            try {
                $tasks = Get-FogActiveTasks;
            } catch {
                $tasks = (Invoke-FogApi -Method GET -uriPath "task/active").tasks;
            }
            $tasks = $tasks | Where-Object { $_.type.id -match '12' -OR $_.type.id -match '13'} #filter task list to all snapins or single snapin task.
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
        }
    
        process {
            Write-Verbose "starting $($PSCmdlet.ParameterSetName) task for host";
            $json = (@{
                "taskTypeID"=$taskTypeid;
                "deploySnapins"=$snapinIDs;
            } | ConvertTo-Json);
            New-FogObject -type objecttasktype -coreTaskObject host -jsonData $json -IDofObject $hostid;
        }
    
        end {
            Write-Verbose "Snapin tasks have been queued on the server";
            return;
        }
    
    }
    