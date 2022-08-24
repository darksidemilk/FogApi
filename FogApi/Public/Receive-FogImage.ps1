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
    
    .NOTES
    Pull and Capture are not powershell approved verbs, they are used as aliases to match the opposite Push-Image alias and to match the name of the task in the fog system.
    Receive is an approved verb and the closest one to what this does

    #>
    [CmdletBinding(DefaultParameterSetName='now')]
    [Alias('Pull-FogImage','Capture-FogImage')]
    param (
        [Parameter(ParameterSetName='now')]
        [Parameter(ParameterSetName='schedule')]
        $hostId,
        [Parameter(ParameterSetName='schedule')]
        [datetime]$StartAtTime
    )
    
    
    process {
        $fogHost = Get-FogHost -hostID $hostId;
        $currentImage = $fogHost.imageName;
        $fogImages = Get-FogImages;
        $fogImage = ($fogImages | Where-Object name -match $currentImage)
        "Creating Capture Task for fog host of id $($hostID) named $($fogHost.name)" | Out-Host;
        "Will capture the assigned image $($fogImage.name) - $($fogImage.id) which will capture the os $($fogImage.osname)" | Out-host;
        if ($PSCmdlet.ParameterSetName -eq 'now') {
            "No Time was specified, queuing the task to start now" | out-host;
		    $jsonData = "{`"taskTypeID`": `"2`" }";
        } else {
            "Start time of $($StartAtTime) specified, scheduling the task to start at that time" | out-host;
            $scheduleTime = Get-FogSecsSinceEpoch -scheduleDate $StartAtTime
            $runTime = get-date $StartAtTime -Format "yyyy-M-d HH:MM"
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
        return New-FogObject -type objecttasktype -coreTaskObject host -jsonData $jsonData -IDofObject "$hostId";
    }
    
}