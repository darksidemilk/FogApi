function Send-FogImage {
    <#
    .SYNOPSIS
    Start or schedule a deploy task for a fog host
    
    .DESCRIPTION
    Starts or schedules a deploy task of the currently assigned image on a host
    
    .PARAMETER hostId
    the hostid to start the deploy task for
    
    .PARAMETER StartAtTime
    The time to start the deploy task, use Get-date to create the required datetime object

    .PARAMETER fogHost
    fogHost object (get-foghost) that can be brought in from pipeline

    .PARAMETER debugMode
    Switch param to mark the task as a debug task

    .PARAMETER imageName
    The name of the image to deploy, uses currently set image if not specified
    Tab completion of your fog server's image names if you're on pwsh 7+

    .PARAMETER NoWol
    Switch param to not use wake on lan in the task, default is to use wake on lan

    .PARAMETER shutdown
    Switch param to indicate the host should shutdown at the end of the task instead of restarting.

    .PARAMETER NoSnapins
    Switch param for when running a scheduled task, you can choose to set deploysnapins to false so the
    assigned snapins aren't auto scheduled too. Only works in FOG 1.6+ and only with scheduled tasks.
    
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
    [CmdletBinding()]
    [Alias('Push-FogImage','Deploy-FogImage')]
    param (
        [Parameter(ParameterSetName='byId')]
        $hostId,
        [Parameter(ValueFromPipeline=$true,ParameterSetName='byhost')]
        $fogHost,
        [datetime]$StartAtTime,
        [ArgumentCompleter({
            param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
            
            $r = Get-FogImages;

            if ($WordToComplete) {
                $r.Name.Where{ $_ -match "^$WordToComplete" }
            }
            else {
                $r.Name
            }
            
        })]  
        [string]$imageName,
        [switch]$debugMode,
        [switch]$NoWol,
        [switch]$shutdown,
        [Parameter(ParameterSetName='schedule')]
        [Parameter(ParameterSetName='schedule-byhost')]
        [switch]$NoSnapins,
        [switch]$force
    )
    
    
    process {
        if ($null -ne $_) {
            $fogHost = $_;
            $hostId = $fogHost.id
        }
        if ($null -ne $hostIdNum) {
            $hostId = $hostIdNum;
        }
        if ($null -ne $fogHostObject) {
            $fogHost = $fogHostObject;
            $hostId = $fogHost.id;
        }
        if ($null -eq $hostId) {
            $hostId = $fogHost.id;
        }
        if ($null -eq $fogHost) {
            $fogHost = Get-FogHost -hostID $hostId;
        }
        # $fogHost = Get-FogHost -hostID $hostId;
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
       

        $tasks = (Get-FogActiveTasks | Where-Object hostid -eq $hostID)
        $schtasks = get-fogobject -type object -coreObject scheduledtask -jsonData "{`"isActive`":`"`1`",`"hostID`":`"$hostID`"}"
        if (($schtasks.data.count -ne 0) -and $force) {
            "Scheduled tasks for this host already exist, canceling them before making new tasks..." | out-host;
            $schtasks.data | ForEach-Object { 
                $removeResult = Remove-FogObject -type object -coreObject scheduledtask -IDofObject $_.id;
                Write-Verbose "Removal of task result was $($removeResult | out-string)"
            }
            $shouldprocess = $true;
        } elseif (($schtasks.data.count -ne 0) -and !$force) {
            Write-Warning "A scheduled task already exists for this host, use -force to remove them before creating a new task, no new task will be created! Existing task will be returned!"
            $shouldprocess = $false;
            return $schtasks.data;
        } elseif (($tasks.count -gt 0) -and $force) {
            "Active tasks for this host already exist, cancelling them before making new tasks..." | out-host;
            $tasks | ForEach-Object {
                $removeResult = Remove-FogObject -type object -coreObject task -IDofObject $_.id;
                Write-Verbose "Removal of task result was $($removeResult | out-string)"
            }
            $shouldprocess = $true;
        } elseif(($tasks.count -gt 0) -and !$force) {
            Write-Warning "A task already exists for this host, use -force to remove them before creating a new task, no new task will be created! Existing task will be returned!"
            $shouldprocess = $false;
            return $tasks;
        } else {
            $shouldprocess = $true;
        }
        
        if ($shouldprocess) {

            $currentImage = $fogHost.imageName;
            $fogImages = Get-FogImages;
            if ($null -ne $imageName) {
                if ($currentImage -eq $imageName) {
                    Write-Verbose "Image $imageName already set on host"
                } else {
                    "Host $($foghost.name) has image $currentImage set, changing image to $imageName!" | out-host;
                    $fogHost = Set-FogHostImage -hostId $fogHost.id -fogImage ($fogImages | Where-Object name -eq $imageName)
                    $currentImage = $fogHost.imageName;
                }
            }
            $fogImage = ($fogImages | Where-Object name -eq $currentImage)
            "Creating Deploy Task for fog host of id $($hostID) named $($fogHost.name)" | Out-Host;
            "Will deploy the assigned image $($fogImage.name) - $($fogImage.id) which will install the os $($fogImage.osname)" | Out-host;
            # if ($PSCmdlet.ParameterSetName -in 'now','now-byhost') {
            if ($null -eq $StartAtTime) {
                "No Time was specified, queuing the task to start now" | out-host;
                if (Test-FogVerAbove1dot6) {
                    $jsonData = @"
                    {
                        "taskName":"Deploy Task for $($fogHost.name) id $($foghost.id)",
                        "taskTypeID":"1",
                        "shutdown":"$shutDownStr",
                        "debug":"$debugStr",
                        "wol":"$wolStr",
                        "isActive":"1"
                    }
"@
                } else {
                    $jsonData = @"
                    {
                        "taskTypeID":"1",
                        "shutdown":"$shutDownStr",
                        "other2":"$debugStr",
                        "other4":"$wolStr",
                        "isActive":"1"
                    }
"@
                }
            } else {
                if ($NoSnapins) {
                    $deploySnapins = $false;
                } else {
                    $deploySnapins = $true;
                }
                "Start time of $($StartAtTime) specified, scheduling the task to start at that time" | out-host;
                $scheduleTime = Get-FogSecsSinceEpoch -scheduleDate $StartAtTime
                $runTime = get-date $StartAtTime -Format "yyyy-M-d HH:MM"
                if (Test-FogVerAbove1dot6) {
                    $jsonData = @"
                        {
                            "taskName":"Deploy Task",
                            "type":"S",
                            "taskTypeID":"1",
                            "runTime":"$runTime",
                            "scheduleTime":"$scheduleTime",
                            "isGroupTask":"0",
                            "hostID":"$($hostId)",
                            "shutdown":"$shutdownStr",
                            "debug":"$debugStr",
                            "wol":"$wolStr",
                            "isActive":"1",
                            "deploySnapins":"$deploySnapins"
                        }
"@
                } else {
                    $jsonData = @"
                        {
                            "name":"Deploy Task",
                            "type":"S",
                            "taskTypeID":"1",
                            "runTime":"$runTime",
                            "scheduleTime":"$scheduleTime",
                            "isGroupTask":"0",
                            "hostID":"$($hostId)",
                            "shutdown":"$shutdownStr",
                            "other2":"$debugStr",
                            "other4":"$wolStr",
                            "isActive":"1"
                        }
"@
                }
            }
            $newTask = New-FogObject -type objecttasktype -coreTaskObject host -jsonData $jsonData -IDofObject "$hostId";
            Write-Verbose "New task created: $($newTask)"
            $task = (Get-FogActiveTasks | Where-Object hostid -eq $hostID)
            return $task;
        }

    }   
}