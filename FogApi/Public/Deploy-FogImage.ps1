function Deploy-FogImage {
    <#
    .SYNOPSIS
    Start or schedule a deploy task for a fog host
    
    .DESCRIPTION
    Starts or schedules a deploy task of the currently assigned image on a host
    
    .PARAMETER hostId
    the hostid to start the deploy task for
    
    .PARAMETER StartAtTime
    The time to start the deploy task, use Get-date to create the required datetime object
    
    .EXAMPLE
    Deploy-FogImage -hostID "1234"

    Will queue a deploy task for host 1234 right now

    .EXAMPLE
    Push-FogImage -hostID "1234" -StartAtTime (Get-date 8pm)

    Using the alias name for this command, Will schedule a deploy task for the host of id 1234 at 8pm the same day

    .EXAMPLE
    Send-FogImage -hostID "1234" -startAtTime ((Get-Date 8pm).adddays(2)).ToDateTime($null)

    Using another alias for this command, will schedule a deploy  task for the host 1234 at 8pm 2 days from now.
    i.e. if today was friday, this would schedule it for sunday at 8pm.
    
    .NOTES
    The verbs used in the main name and alias names are meant to provide better usability as someone may search for approved powershell verbs 
    when looking for this functionality or may simply look for deploy as that is the name of the task in fog. It just happens to be an approved powershell verb too
    #>
    [CmdletBinding(DefaultParameterSetName='now')]
    [Alias('Push-FogImage','Send-FogImage')]
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
        "Creating Deploy Task for fog host of id $($hostID) named $($fogHost.name)" | Out-Host;
        "Will deploy the assigned image $($fogImage.name) - $($fogImage.id) which will install the os $($fogImage.osname)" | Out-host;
        if ($PSCmdlet.ParameterSetName -eq 'now') {
            "No Time was specified, queuing the task to start now" | out-host;
            $jsonData = "{`"taskTypeID`": `"1`", `"shutdown`":`"0`",`"other2`":`"0`",`"other4`":`"1`",`"isActive`":`"1`" }";
        } else {
            "Start time of $($StartAtTime) specified, scheduling the task to start at that time" | out-host;
            $scheduleTime = Get-FogSecsSinceEpoch -scheduleDate $StartAtTime
            $runTime = get-date $StartAtTime -Format "yyyy-M-d HH:MM"
            $jsonData = @"
                    {
                        "name":"Deploy Task",
                        "type":"S",
                        "taskTypeID":"1",
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