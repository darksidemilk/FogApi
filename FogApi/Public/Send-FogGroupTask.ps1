function Send-FogGroupTask {
<#
    .SYNOPSIS
    Queues a task against every host in a fog group at once

    .DESCRIPTION
    Creates an immediate task (or, if -StartAtTime is given, a scheduled task) against a whole group of hosts in one call,
    instead of looping New-FogObject/Send-FogImage per host.
    Uses taskTypeID 1 (deploy) by default, the same default fog uses for a normal image deploy task.

    .PARAMETER groupObj
    A fog group object (e.g. from Get-FogGroups) to queue the task for. Supports pipeline input.

    .PARAMETER groupID
    The id of the group to queue the task for

    .PARAMETER taskTypeID
    The fog task type id to queue, defaults to 1 (deploy). See your fog server's task type list for other values (e.g. capture, memtest, etc.)

    .PARAMETER StartAtTime
    The time to start the task, use Get-date to create the required datetime object. If omitted the task is queued to start immediately.

    .PARAMETER debugMode
    Switch param to mark the task as a debug task. Only applies to immediate tasks.

    .PARAMETER NoWol
    Switch param to not use wake on lan in the task, default is to use wake on lan

    .PARAMETER shutdown
    Switch param to indicate hosts should shutdown at the end of the task instead of restarting.

    .PARAMETER NoSnapins
    Switch param for scheduled tasks, sets deploysnapins to false so assigned snapins aren't auto scheduled too. Only works in FOG 1.6+ and only with scheduled tasks.

    .PARAMETER bypassbitlocker
    Switch param to bypass bitlocker checks, this will set the bitlocker flag to 1 in the task, this is the 'other5' property.

    .EXAMPLE
    Send-FogGroupTask -groupID 7 -taskTypeID 14

    Queues an immediate wake-up task for every host in the group with id 7.
    Use the default taskTypeID of 1 to queue a deploy task instead.

    Expected output:
    { "id": 501, "success": true }

    .EXAMPLE
    Get-FogGroupByName "TestGroup" | Send-FogGroupTask -taskTypeID 14 -StartAtTime ((Get-Date).AddHours(2))

    Finds the group named "TestGroup" and schedules a wake-up task for every host in it 2 hours from now,
    returning the created scheduled task marked as a group task.

    Expected output:
    { "type": "S", "isGroupTask": "1" }

    .NOTES
    Verified against the fog server source (FOGProject/fogproject, working-1.6 branch, packages/web/lib/router/route.class.php and
    packages/web/lib/fog/scheduledtask.class.php):
    - Immediate group tasks use the "group" coreTaskObject (POST group/{id}/task), routed to Route::task() which calls
      Group::createImagePackage() when the target class is a Group. Reads taskTypeID, taskName, shutdown, debug, wol, deploySnapins.
    - Scheduled group tasks go through the generic scheduledtask create() route. The scheduledtask table has no separate groupID column -
      "isGroupTask":"1" instead repurposes the "hostID" field (db column stGroupHostID) to hold the group id, so this cmdlet sends
      "hostID":"$groupID" rather than a "groupID" field. The scheduledtask create route only maps JSON keys that literally match its
      databaseFields, so the task's name field must be sent as "name", not "taskName".
#>

    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline=$true,ParameterSetName='byObj')]
        $groupObj,
        [parameter(Mandatory=$true,ParameterSetName='byId')]
        $groupID,
        $taskTypeID = 1,
        [datetime]$StartAtTime,
        [switch]$debugMode,
        [switch]$NoWol,
        [switch]$shutdown,
        [switch]$NoSnapins,
        [switch]$bypassbitlocker
    )

    process {
        if ($null -ne $_) {
            $groupObj = $_;
        }
        if ($null -ne $groupObj) {
            $groupID = $groupObj.id;
        }

        $debugStr = "$($debugMode.IsPresent.toInt64($null))";
        if ($NoWol) {
            $wolStr = "0"
        } else {
            $wolStr = "1"
        }
        if ($shutdown) {
            $shutdownStr = "1"
        } else {
            $shutdownStr = "0"
        }
        $bitlockerStr = "$($bypassbitlocker.IsPresent.ToInt64($null))";

        if ($null -eq $StartAtTime) {
            "Queuing an immediate task of type $taskTypeID for every host in group $groupID" | Out-Host;
            if (Test-FogVerAbove1dot6) {
                $jsonData = @"
                {
                    "taskName":"Group Task for group id $groupID",
                    "taskTypeID":"$taskTypeID",
                    "shutdown":"$shutdownStr",
                    "debug":"$debugStr",
                    "wol":"$wolStr",
                    "isActive":"1"
                }
"@
            } else {
                $jsonData = @"
                {
                    "taskTypeID":"$taskTypeID",
                    "shutdown":"$shutdownStr",
                    "other2":"$debugStr",
                    "other4":"$wolStr",
                    "isActive":"1"
                }
"@
            }
            return New-FogObject -type objecttasktype -coreTaskObject group -jsonData $jsonData -IDofObject $groupID;
        } else {
            if ($NoSnapins) {
                $deploySnapins = "0";
            } else {
                $deploySnapins = "-1";
            }
            "Scheduling a task of type $taskTypeID for every host in group $groupID to start at $StartAtTime" | Out-Host;
            $scheduleTime = Get-FogSecsSinceEpoch -scheduleDate $StartAtTime
            $runTime = Get-Date $StartAtTime -Format "yyyy-M-d HH:MM"
            if (Test-FogVerAbove1dot6) {
                $jsonData = @"
                    {
                        "name":"Group Task",
                        "description":"Scheduled Group Task for group id $groupID on $($StartAtTime.DateTime.ToString())",
                        "type":"S",
                        "taskTypeID":"$taskTypeID",
                        "runTime":"$runTime",
                        "scheduleTime":"$scheduleTime",
                        "isGroupTask":"1",
                        "hostID":"$groupID",
                        "shutdown":"$shutdownStr",
                        "debug":"$debugStr",
                        "wol":"$wolStr",
                        "other2":"$deploySnapins",
                        "other3":"API",
                        "other4":"$wolStr",
                        "other5":"$bitlockerStr",
                        "isActive":"1",
                        "deploySnapins":"$deploySnapins"
                    }
"@
            } else {
                $jsonData = @"
                    {
                        "name":"Group Task",
                        "type":"S",
                        "taskTypeID":"$taskTypeID",
                        "runTime":"$runTime",
                        "scheduleTime":"$scheduleTime",
                        "isGroupTask":"1",
                        "hostID":"$groupID",
                        "shutdown":"$shutdownStr",
                        "other2":"$deploySnapins",
                        "other3":"API",
                        "other4":"$wolStr",
                        "other5":"$bitlockerStr",
                        "isActive":"1"
                    }
"@
            }
            return New-FogObject -type object -coreObject scheduledtask -jsonData $jsonData;
        }
    }

}
