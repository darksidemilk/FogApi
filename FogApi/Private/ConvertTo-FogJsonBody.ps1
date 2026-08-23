function ConvertTo-FogJsonBody {
<#
.SYNOPSIS
Normalises a request body to the JSON string Invoke-FogApi sends.

.DESCRIPTION
The L1 cmdlets have always documented their body as a JSON string the caller
composes:

    Update-FogObject -type object -coreObject host -IDofObject $h.id `
        -jsonData ($h | Select-Object aduser | ConvertTo-Json -Compress)

That ceremony is the thing Phase 2 removes. New-FogObject and Update-FogObject
declare -jsonData as [Object], so a hashtable or an object could always be
PASSED -- but Invoke-FogApi's own -jsonData is [string], and splatting a
hashtable into a [string] parameter does not fail, it stringifies. The body on
the wire became the literal text "System.Collections.Hashtable" and the server
answered with a validation error about missing fields, which reads like a bug in
the payload rather than in the plumbing.

So the conversion has to happen before the splat, which is what this does.
Invoke-FogApi stays the single HTTP choke point taking a string, and the two L1
cmdlets stop caring what shape they were handed:

    string        passed through untouched -- it is already JSON, and
                  re-serialising it would double-encode
    FogTaskRequest  ToJson(), the FOG 1.6 spelling of the task body
    hashtable     ConvertTo-Json
    PSCustomObject  ConvertTo-Json
    $null         $null, so Invoke-FogApi still drops the body for a GET

On FogTaskRequest this deliberately returns the 1.6 body. Choosing between that
and ToLegacyBody() needs the server version, and asking for it here would put a
GET system/info in front of every write. Every task cmdlet already branches on
Test-FogVerAbove1dot6, so the one that knows calls ToJsonForServer() and hands
this a string.

-Depth 10 because a host carries nested inventory, image and hostscreen objects
and ConvertTo-Json's default of 2 silently renders anything deeper as the type
name. -Compress only to keep request logs readable.

.PARAMETER Body
The body to normalise.

.EXAMPLE
ConvertTo-FogJsonBody -Body @{ name = 'somehost' }

Returns {"name":"somehost"}.
#>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Position = 0)]
        [Object]$Body
    )

    process {
        if ($null -eq $Body) { return $null }

        # Already JSON. Passing a string through untouched is what keeps every
        # existing caller working unchanged.
        if ($Body -is [string]) { return $Body }

        if ($Body -is [System.Management.Automation.PSObject] -and $Body.BaseObject -is [string]) {
            return [string]$Body.BaseObject
        }

        # Any input class that can render itself. Checked by capability rather
        # than by name so the per-entity input classes, if they ever land, need
        # no change here.
        $toJson = $Body.PSObject.Methods['ToJson']
        if ($null -ne $toJson) { return [string]$toJson.Invoke() }

        return ($Body | ConvertTo-Json -Depth 10 -Compress)
    }
}
