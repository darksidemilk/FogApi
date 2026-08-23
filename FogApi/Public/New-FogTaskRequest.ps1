function New-FogTaskRequest {
<#
.SYNOPSIS
Builds a task request body for the cmdlets that queue FOG tasks.

.DESCRIPTION
Returns a FogTaskRequest -- the object form of the body FOG's own OpenAPI
document describes for POST /{class}/{id}/task. Pass it to Send-FogImage,
Receive-FogImage, Send-FogGroupTask, Send-FogWolTask, Start-FogSnapin or
Start-FogSnapins with -TaskRequest, or straight to New-FogObject as -jsonData.

This cmdlet exists because a PowerShell class does not escape its module: after
Import-Module FogApi, a caller writing [FogTaskRequest]@{...} gets "Unable to
find type", because naming a module's class requires `using module FogApi`
instead of an import. Measured, not assumed. So the type gets a factory, the way
the rest of PowerShell reaches types it cannot name.

Two other ways in, both of which work without this cmdlet:

    Send-FogImage -hostName somehost -TaskRequest @{ taskTypeID = 1; shutdown = $true }
    New-FogObject -type objecttasktype -coreTaskObject host -IDofObject 42 -jsonData @{ taskTypeID = 13 }

A hashtable converts on binding and rejects a misspelled field by name, listing
the ones it accepts. What it does not give you is tab completion, which is the
reason to prefer this cmdlet when typing at a prompt.

Only the fields you set are sent. Unset ones are omitted rather than sent as a
deliberate 0, which is why the switch-like fields are [bool] parameters rather
than [switch]: -shutdown:$false says "shut down: no" and leaving it out says
nothing at all, and FOG treats those differently.

.PARAMETER taskTypeID
The task type. 1 deploy, 2 capture, 13 single snapin, 14 wake-on-lan, 17 all
snapins. Get-FogObject -type object -coreObject tasktype lists what a server has.

.PARAMETER taskName
The name the task appears under in the FOG UI.

.PARAMETER shutdown
Shut the host down when the task finishes instead of restarting it.

.PARAMETER debugMode
Queue the task in debug mode, which drops to a shell on the client instead of
running unattended. FOG refuses to schedule a debug task for later.

The document calls this field 'debug' and the body still says debug on the wire,
but -Debug is a PowerShell common parameter, so a -debug parameter here is a
duplicate-name error at import rather than a shadowing warning. -debugMode is
what Send-FogImage and Receive-FogImage have always called it.

.PARAMETER deploySnapins
-1 for every snapin assigned to the host, 0 for none, or a single snapin id.

.PARAMETER passreset
The account name to reset the password for, on a password-reset task.

.PARAMETER sessionjoin
Join the host to an existing multicast session rather than starting one.

.PARAMETER wol
Send a wake-on-lan packet before the task starts.

.PARAMETER extra
Fields this module does not model, merged over the body last. The same escape
hatch the generated cmdlets spell -settings.

.EXAMPLE
New-FogTaskRequest -taskTypeID 1 -taskName 'Deploy' -shutdown $true

Builds an immediate deploy task that shuts the host down afterwards.
Expected output:
{ "taskTypeID": 1, "taskName": "Deploy", "shutdown": true }

.EXAMPLE
$t = New-FogTaskRequest -taskTypeID 13 -deploySnapins 7
Get-FogHost -hostName somehost | Start-FogSnapin -TaskRequest $t

Queues snapin 7 against a host, passing the request object down the pipeline.

.EXAMPLE
(New-FogTaskRequest -taskTypeID 14 -wol $true).ToJson()

Shows the exact body that would be sent: {"taskTypeID":"14","wol":"1"}.
Only the fields that were set appear.
#>
    [CmdletBinding()]
    [Alias('New-FogTaskBody')]
    [OutputType('FogTaskRequest')]
    param (
        [Parameter(Position = 0)]
        [Alias('typeID')]
        [Nullable[int]]$taskTypeID,

        [Parameter(Position = 1)]
        [Alias('name')]
        [string]$taskName,

        [Nullable[bool]]$shutdown,

        [Alias('isDebug')]
        [Nullable[bool]]$debugMode,

        [Nullable[int]]$deploySnapins,

        [string]$passreset,

        [Nullable[bool]]$sessionjoin,

        [Nullable[bool]]$wol,

        [hashtable]$extra
    )

    process {
        # Only what was actually bound. Assigning every parameter would turn an
        # unmentioned field into an explicit value, which is the distinction
        # this cmdlet exists to preserve.
        $request = [FogTaskRequest]::new()
        # The wire field is 'debug'; the parameter cannot be, so it is the one
        # name that does not map straight through.
        $parameterFor = @{ debug = 'debugMode' }
        foreach ($field in [FogTaskRequest]::FieldNames()) {
            $parameter = $(if ($parameterFor.ContainsKey($field)) { $parameterFor[$field] } else { $field })
            if ($PSBoundParameters.ContainsKey($parameter)) {
                $request.$field = $PSBoundParameters[$parameter]
            }
        }
        if ($PSBoundParameters.ContainsKey('extra')) { $request.extra = $extra }
        return $request
    }
}
