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
    i.e. (get-date 8pm) for 8pm today or (get-date 2am).adddays(1) for 2am tomorrow.

    .PARAMETER fogHost
    fogHost object (get-foghost) that can be brought in from pipeline

    .PARAMETER debugMode
    Switch param to mark the task as a debug task. Will switch to an immediate task if a start time is specified.
    Debug mode is only available for immediate tasks, it will not work with scheduled tasks.

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
    If you specify this switch without a startattime it will automatically set the start time to 5 seconds from now.

    .PARAMETER force
    Switch param to force the removal of existing tasks for this host before creating a new task.
    If you do not use this switch and a task already exists, the existing task will be returned instead of creating a new one.
    Will search for both active tasks and scheduled tasks, if either exist, it will not create a new task unless you use this switch.
    
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

    .EXAMPLE
    Send-FogImage -fogHost (Get-FogHost -hostname "comp-name") -imageName "Windows 10"

    Will find the host by name "comp-name" and send the the image right now.

    .EXAMPLE
    Get-foghost -hostname "comp-name" | Send-FogImage -startAtTime (Get-Date 8pm) -debugMode

    Will get the foghost object of name 'comp-name' and pipe it into the command. It will queue a debug deploy task for the host at 8pm the same day.
    
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
        #it seems that debugmode value reverted to 1 and 0 instead of true and false in FOG 1.6
        # if (Test-FogVerAbove1dot6) {
            # $debugstr = "$($debugMode.IsPresent)"
        # } else {
            # if ($debugMode) {
            #     $debugStr = "1"
            # } else {
            #     $debugStr = "0"
            # }
        # }
        $debugStr = "$($debugMode.IsPresent.toInt64($null))";
        if (($debugMode) -and ($null -ne $StartAtTime)) {
            Write-Warning "You cannot use -debugMode with a scheduled task, debug mode requires the task to start immediately, switching to immediate start"
            $StartAtTime = $null;
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
        if (($NoSnapins) -and ($null -eq $StartAtTime) -and !($debugMode)) {
            Write-Warning "-NoSnapins only works with scheduled tasks, adding a scheduled start time of 5 seconds from now, may still take 1-2 minutes for FOG.SCHEDULER service to pick up the task and run it"
            $StartAtTime = (Get-Date).AddSeconds(5);
        } else {
            if ($NoSnapins -and $debugMode) {
                Write-Warning "-NoSnapins does not work with debug mode because nosnapins requires a scheduled task and debug mode requires an immediate task, ignoring -NoSnapins"
            }
        }
       

        $tasks = (Get-FogActiveTasks | Where-Object hostid -eq $hostID)
        $schtasks = (Get-FogScheduledTasks | Where-Object hostid -eq $hostID)
        if (($schtasks.count -ne 0) -and $force) {
            "Scheduled tasks for this host already exist, canceling them before making new tasks..." | out-host;
            $schtasks | ForEach-Object { 
                $removeResult = Remove-FogObject -type object -coreObject scheduledtask -IDofObject $_.id;
                Write-Verbose "Removal of task result was $($removeResult | out-string)"
            }
            $shouldprocess = $true;
        } elseif (($schtasks.count -ne 0) -and !$force) {
            Write-Warning "A scheduled task already exists for this host, use -force to remove them before creating a new task, no new task will be created! Existing task will be returned!"
            $shouldprocess = $false;
            return $schtasks;
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
            if ((Test-StringNotNullOrEmpty $imageName)) {
                if ($currentImage -eq $imageName) {
                    Write-Verbose "Image $imageName already set on host"
                } else {
                    "Host $($foghost.name) has image $currentImage set, changing image to $imageName!" | out-host;
                    $fogHost = Set-FogHostImage -hostId $fogHost.id -fogImage ($fogImages | Where-Object name -eq $imageName)
                    $currentImage = $fogHost.imageName;
                }
            } else {
                "No image name specified, using currently assigned image $currentImage" | out-host;
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
                $newtask = New-FogObject -type objecttasktype -coreTaskObject host -jsonData $jsonData -IDofObject $hostId;
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
                            "description":"Scheduled Deploy Task for $($fogHost.name) id $($foghost.id) on $($StartAtTime.DateTime.ToString())",
                            "type":"S",
                            "taskTypeID":"1",
                            "runTime":"$runTime",
                            "scheduleTime":"$scheduleTime",
                            "isGroupTask":"0",
                            "hostID":"$($hostId)",
                            "shutdown":"$shutdownStr",
                            "debug":"$($debugmode.ispresent)",
                            "wol":"$wolStr",
                            "other2":"$debugStr",
                            "other3":"API",
                            "other4":"$wolStr",
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
                            "other3":"API",
                            "other4":"$wolStr",
                            "isActive":"1"
                        }
"@
                }
                $newtask = New-FogObject -type object -coreObject scheduledtask -jsonData $jsonData
            }

            if ($null -ne $StartAtTime) {
                $task = Get-FogScheduledTasks | Where-Object hostid -eq $hostID;
            } elseif (($null -eq $task) -or ($null -eq $StartAtTime)) {
                $task = (Get-FogActiveTasks | Where-Object hostid -eq $hostID)
            } else {
                Write-Warning "Task was not found in active scheduled tasks or active tasks, returning the result of creating the new task."
                $task = $newtask;
            }

            Write-Verbose "New task created: $($newTask)"
            return $task;
        }

    }   
}