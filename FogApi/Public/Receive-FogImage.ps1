function Receive-FogImage {
    <#
    .SYNOPSIS
    Starts or schedules a capture task on a given host
    
    .DESCRIPTION
    Starts a capture task to receive a new version of an image in fog
    
    .PARAMETER hostId
    The id of the host to capture from
    
    .PARAMETER StartAtTime
    When to start to capture, if not given will start now

    .PARAMETER fogHost
    fogHost object (get-foghost) that can be brought in from pipeline

    .PARAMETER NoWol
    Switch param to not use wake on lan in the task, default is to use wake on lan

    .PARAMETER debugMode
    Switch param to mark the task as a debug task

    .PARAMETER shutdown
    Switch param to indicate the host should shutdown at the end of the task instead of restarting.
    
    .EXAMPLE
    Receive-FogImage -hostID "1234"

    Will queue a capture task for host 1234 right now

    .EXAMPLE
    Capture-FogImage -hostID "1234" -StartAtTime (Get-date 8pm)

    Using the alias name for this command, Will schedule a capture task for the host of id 1234 at 8pm the same day

    .EXAMPLE
    Pull-FogImage -hostID "1234" -startAtTime ((Get-Date 8pm).adddays(2)).ToDateTime($null)

    Using another alias for this command, will schedule a capture task for the host 1234 at 8pm 2 days from now.
    i.e. if today was friday, this would schedule it for sunday at 8pm.

    .EXAMPLE
    Get-FogHost | Receive-FogImage -debugMode -shutdown

    Capture an image from the current host right now in debug mode, shutdown the computer after complete
    
    .NOTES
    Pull and Capture are not powershell approved verbs, they were used as aliases to match the opposite 
    Push-Image alias and to match the name of the task in the fog system but that caused a constant warning when importing the module
    Receive is an approved verb and the closest one to what this does, Save-FogImage is another alias as is Invoke-FogImageCapture.

    #>
    [CmdletBinding(DefaultParameterSetName='now')]
    [Alias('Save-FogImage','Invoke-FogImageCapture','Capture-FogImage','Pull-FogImage')]
    param (
        [Parameter(ParameterSetName='now')]
        [Parameter(ParameterSetName='schedule')]
        $hostId,
        [Parameter(ValueFromPipeline=$true,ParameterSetName='now-byhost')]
        [Parameter(ValueFromPipeline=$true,ParameterSetName='schedule-byhost')]
        $fogHost,
        [Parameter(ParameterSetName='schedule')]
        [Parameter(ParameterSetName='schedule-byhost')]
        [datetime]$StartAtTime,
        [Parameter(ParameterSetName='now')]
        [Parameter(ParameterSetName='now-byhost')]
        [Parameter(ParameterSetName='schedule')]
        [Parameter(ParameterSetName='schedule-byhost')]
        [switch]$debugMode,
        [Parameter(ParameterSetName='now')]
        [Parameter(ParameterSetName='now-byhost')]
        [Parameter(ParameterSetName='schedule')]
        [Parameter(ParameterSetName='schedule-byhost')]
        [switch]$NoWol,
        [Parameter(ParameterSetName='now')]
        [Parameter(ParameterSetName='now-byhost')]
        [Parameter(ParameterSetName='schedule')]
        [Parameter(ParameterSetName='schedule-byhost')]
        [switch]$shutdown
    )
    
    
    process {
        if ($null -ne $_) {
            $fogHost = $_;
            $hostId = $fogHost.id
        } 
        if ($null -eq $hostId) {
            $hostId = $fogHost.id;
        }
        if ($null -eq $fogHost) {
            $fogHost = Get-FogHost -hostID $hostId;
        }

        if (Test-FogVerAbove1dot6) {
            $debugstr = "$($debugMode.IsPresent)"
        } else {
            if ($debugMode) {
                $debugStr = "0"
            } else {
                $debugStr = "1"
            }
        }
        if ($Nowol) {
            $wolstr = "0"
        } else {
            $wolStr = "1"
        }
        if ($shutdown) {
            $shutdownStr = "1"
        } else {
            $shutdownStr = "0"
        }
        
        $currentImage = $fogHost.imageName;
        $fogImages = Get-FogImages;
        $fogImage = ($fogImages | Where-Object name -match $currentImage)
        "Creating Capture Task for fog host of id $($hostID) named $($fogHost.name)" | Out-Host;
        "Will capture the assigned image $($fogImage.name) - $($fogImage.id) which will capture the os $($fogImage.osname)" | Out-host;
        if ($PSCmdlet.ParameterSetName -eq 'now') {
            "No Time was specified, queuing the task to start now" | out-host;
		    if (Test-FogVerAbove1dot6) {

                $jsonData = @"
                {
                    "taskName":"Capture Task",
                    "taskTypeID": "2",
                    "shutdown":"$shutDownStr",
                    "debug":"$debugStr",
                    "wol":"$wolStr",
                    "isActive":"1"
                }
"@
            } else {
                $jsonData = @"
                {
                    "taskTypeID": "2"
                    "shutdown":"$shutDownStr",
                    "other2":"$debugStr",
                    "other4":"$wolStr",
                    "isActive":"1"
                }
"@
            }

        } else {
            "Start time of $($StartAtTime) specified, scheduling the task to start at that time" | out-host;
            $scheduleTime = Get-FogSecsSinceEpoch -scheduleDate $StartAtTime
            $runTime = get-date $StartAtTime -Format "yyyy-M-d HH:MM"
            if (Test-FogVerAbove1dot6) {
                $jsonData = @"
                {
                    "taskName":"Capture Task",
                    "type":"S",
                    "taskTypeID":"2",
                    "runTime":"$runTime",
                    "scheduleTime":"$scheduleTime",
                    "isGroupTask":"0",
                    "hostID":"$($hostId)",
                    "shutdown":"$shutdownStr",
                    "debug":"$debugStr",
                    "wol":"$wolStr",
                    "isActive":"1"
                }
"@
            } else {

                $jsonData = @"
                {
                    "name":"Capture Task",
                    "type":"S",
                    "taskTypeID":"2",
                    "runTime":"$runTime",
                    "scheduleTime":"$scheduleTime",
                    "isGroupTask":"0",
                    "hostID":"$($hostId)",
                    "shutdown":"0",
                    "other2":"0",
                    "other4":"1",
                    "isActive":"1"
                }
"@
            }
        }
        return New-FogObject -type objecttasktype -coreTaskObject host -jsonData $jsonData -IDofObject "$hostId";
    }
    
}