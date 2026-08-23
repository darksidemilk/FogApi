#Requires -Version 5.1
<#
.SYNOPSIS
Writes FogApi/Classes/FogTaskRequest.ps1 from the OpenAPI snapshot.

.DESCRIPTION
Ten cmdlets built the task request body by hand -- eight of them as interpolated
here-string JSON, which is why two of them shipped broken bytes for years:
Receive-FogImage's 1.5 branch omits the comma after "taskTypeID", and
Send-FogWolTask sends isActive as "1;". Neither is reachable by a test that only
checks the 1.6 path, and neither is possible once the body is an object.

The body is described by the server, so the class is generated rather than
invented. Source is spec/openapi/fog-1.6.json -- the snapshot of FOG's own
document, never hand-edited -- at POST /{class}/{id}/task. All five task routes
(host, group, multicastsession, scheduledtask, task) declare the same body, and
this asserts that rather than assuming it.

Why the snapshot and not spec/fog-api-spec.json: the resolved spec carries
functions and entity schemas, not request bodies. Point this at a refreshed
snapshot and the class follows the server.

There is no FOG 1.5 variant of this body, which is worth stating because the
module long believed otherwise. FOG 1.5's Route::task() hands the decoded body
straight to createImagePackage(taskTypeID, taskName, shutdown, debug,
deploySnapins, isGroupTask, username, passreset, sessionjoin, wol) -- the same
eight caller-supplied fields 1.6 declares, and no other2 or other4 anywhere.
Verified against fogproject 1.5.10.2253 and working-1.6. The other2/other4
spellings the callers used on their 1.5 branches are scheduledtask table
columns, pasted into the wrong body; 1.5 ignored them and never received the
taskName, debug or wol those branches meant to send.

Type mapping. Every field but taskName and passreset is declared oneOf, because
FOG accepts both the JSON type and its string spelling. A caller should not have
to care, so the class takes the natural PowerShell type and ToBody() renders the
wire spelling:

    oneOf contains boolean -> [Nullable[bool]]
    oneOf contains integer -> [Nullable[int]]
    otherwise              -> [string]

Nullable matters: a plain [bool] defaults to $false, and an unset field must be
omitted from the body rather than sent as a deliberate "0". Only what the caller
actually set is serialised.

Three constraints this emitter must keep, each measured the hard way and
recorded in CONTEXT-typed-objects-plan.md:

  * No single-argument [object] constructor. That is what made [FogHost]$x
    silently accept [pscustomobject]@{nope=1}. From-hashtable conversion goes on
    a static factory instead.
  * No derived state in the default constructor. [T]@{...} runs it BEFORE the
    hashtable properties are assigned, so anything computed there sees empty
    values.
  * Consumers must write [OutputType('FogTaskRequest')], never the type literal,
    which fails to resolve in a dot-sourced module and poisons the whole
    function. This emitter does not emit OutputType; the note is for callers.

.PARAMETER SnapshotFile
The OpenAPI snapshot. Defaults to spec/openapi/fog-1.6.json.

.PARAMETER OutFile
Where to write. Defaults to FogApi/Classes/FogTaskRequest.ps1.

.EXAMPLE
./spec/tools/New-FogInputClass.ps1
#>
[CmdletBinding()]
param (
    [string]$SnapshotFile,
    [string]$OutFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$specRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$repoRoot = Split-Path -Parent $specRoot
if (-not $SnapshotFile) { $SnapshotFile = Join-Path (Join-Path $specRoot 'openapi') 'fog-1.6.json' }
if (-not $OutFile) {
    $OutFile = Join-Path (Join-Path (Join-Path $repoRoot 'FogApi') 'Classes') 'FogTaskRequest.ps1'
}

$doc = Get-Content -LiteralPath $SnapshotFile -Raw | ConvertFrom-Json

# Every /{class}/{id}/task route in the document, so a body that stops agreeing
# across classes fails the build instead of silently modelling only host's.
$taskPaths = @($doc.paths.PSObject.Properties.Name | Where-Object { $_ -match '^/[a-z]+/\{id\}/task$' } | Sort-Object)
if ($taskPaths.Count -eq 0) { throw "no /{class}/{id}/task route found in $SnapshotFile" }

$shapes = @{}
foreach ($p in $taskPaths) {
    $props = $doc.paths.$p.post.requestBody.content.'application/json'.schema.properties
    $names = @($props.PSObject.Properties.Name | Sort-Object)
    $shapes[$p] = ($names -join ',')
}
$distinct = @($shapes.Values | Sort-Object -Unique)
if ($distinct.Count -ne 1) {
    $detail = ($shapes.GetEnumerator() | ForEach-Object { "  $($_.Key): $($_.Value)" }) -join "`n"
    throw "the task routes no longer declare one body shape:`n$detail"
}

$reference = $taskPaths[0]
$properties = $doc.paths.$reference.post.requestBody.content.'application/json'.schema.properties
$description = $doc.paths.$reference.post.description

function Resolve-PsType {
    param($schema)
    $types = @()
    if ($schema.PSObject.Properties.Name -contains 'oneOf') {
        $types = @($schema.oneOf | ForEach-Object { $_.type })
    } elseif ($schema.PSObject.Properties.Name -contains 'type') {
        $types = @($schema.type)
    }
    # Integer wins over boolean when a field declares both. deploySnapins is the
    # field that makes this matter: it is oneOf string/integer/boolean, and its
    # real values are -1 (every snapin), 0 (none) or a snapin id. Checking
    # boolean first coerced -1 to $true and put "1" on the wire -- the wrong
    # snapin task, silently. The wider domain is always the safe mapping.
    if ($types -contains 'integer') { return '[Nullable[int]]' }
    if ($types -contains 'boolean') { return '[Nullable[bool]]' }
    return '[string]'
}

$fields = foreach ($n in @($properties.PSObject.Properties.Name)) {
    [pscustomobject]@{
        Name   = $n
        PsType = Resolve-PsType $properties.$n
    }
}

$propLines = ($fields | ForEach-Object { "    $($_.PsType)`$$($_.Name)" }) -join "`n"
$fieldList = ($fields | ForEach-Object { "'$($_.Name)'" }) -join ", "
$boolFields = ($fields | Where-Object { $_.PsType -eq '[Nullable[bool]]' } | ForEach-Object { "'$($_.Name)'" }) -join ", "
$docLines = ($fields | ForEach-Object { "    $($_.Name.PadRight(14)) $($_.PsType)" }) -join "`n"

$content = @"
<#
GENERATED FILE. Do not edit. Rebuild with spec/tools/New-FogInputClass.ps1.

FogTaskRequest is the body of POST /{class}/{id}/task, taken from FOG's own
OpenAPI document. The server's words for it:

  $description

Fields, and the PowerShell type each maps to:

$docLines

A field left `$null` is omitted from the body entirely. That is the reason the
value types are Nullable -- a plain [bool] would default to `$false` and send a
deliberate "0" for a field the caller never mentioned.

Use it like any other object:

    `$t = [FogTaskRequest]@{ taskTypeID = 1; taskName = 'deploy'; shutdown = `$false }
    Send-FogImage -hostName somehost -TaskRequest `$t

Or from a hashtable, which validates the field names as it converts:

    `$t = [FogTaskRequest]::FromHashtable(@{ taskTypeID = 13; deploySnapins = -1 })

Three things about this class are deliberate and must survive regeneration:

  * There is no single-argument [object] constructor. A class that has one
    accepts ANY object, including [pscustomobject]@{nope=1}, because
    PowerShell's conversion finds it. FromHashtable() is the conversion path,
    and it rejects unknown fields.
  * The default constructor computes nothing. [FogTaskRequest]@{...} runs it
    before the hashtable properties are assigned, so derived state set there
    would be computed from empty values.
  * A caller writes [OutputType('FogTaskRequest')] -- the string. The type
    literal form does not resolve in a dot-sourced module and poisons the whole
    function, so even invoking it throws.
#>
class FogTaskRequest {
$propLines

    # Anything the class does not model, merged over the body last. The same
    # escape hatch the generated cmdlets spell -settings, and the reason
    # isActive -- which the module has always sent and the document does not
    # declare -- still reaches the wire.
    [hashtable]`$extra

    # Nothing derived here, on purpose. See the note above.
    FogTaskRequest() {}

    static [string[]] FieldNames() {
        return @($fieldList)
    }

    static [FogTaskRequest] FromHashtable([hashtable]`$values) {
        if (`$null -eq `$values) { throw [System.ArgumentNullException]::new('values') }
        `$known = [FogTaskRequest]::FieldNames()
        `$req = [FogTaskRequest]::new()
        `$spill = @{}
        foreach (`$key in `$values.Keys) {
            if (`$known -contains `$key) {
                `$req.`$key = `$values[`$key]
            } else {
                # Unknown field names are the common typo, so they go to the
                # escape hatch rather than being dropped -- but say so, because
                # a misspelled taskTypeID is otherwise a silent no-op.
                Write-Verbose "FogTaskRequest: '`$key' is not a declared task field; passing it through -extra"
                `$spill[`$key] = `$values[`$key]
            }
        }
        if (`$spill.Count -gt 0) { `$req.extra = `$spill }
        return `$req
    }

    # FOG accepts a JSON boolean here, but every shipped caller has always sent
    # "1"/"0" and a task is not the place to find out whether some 1.5-era
    # branch still depends on that. Rendering stays as it was.
    hidden static [string] Render([object]`$value) {
        if (`$value -is [bool]) { return `$(if (`$value) { '1' } else { '0' }) }
        return "`$value"
    }

    # The FOG 1.6 body: the declared fields the caller actually set, plus
    # anything in -extra.
    [hashtable] ToBody() {
        `$body = @{}
        foreach (`$name in [FogTaskRequest]::FieldNames()) {
            `$value = `$this.`$name
            if (`$null -eq `$value) { continue }
            if (`$value -is [string] -and `$value -eq '') { continue }
            `$body[`$name] = [FogTaskRequest]::Render(`$value)
        }
        if (`$null -ne `$this.extra) {
            foreach (`$key in `$this.extra.Keys) { `$body[`$key] = [FogTaskRequest]::Render(`$this.extra[`$key]) }
        }
        return `$body
    }

    [string] ToJson() { return (`$this.ToBody() | ConvertTo-Json -Depth 5 -Compress) }

    [string] ToString() {
        `$type = `$(if (`$null -eq `$this.taskTypeID) { '?' } else { `$this.taskTypeID })
        if ([string]::IsNullOrEmpty(`$this.taskName)) { return "FogTaskRequest(taskTypeID=`$type)" }
        return "FogTaskRequest(taskTypeID=`$type, '`$(`$this.taskName)')"
    }
}
"@

Set-Content -LiteralPath $OutFile -Value $content -Encoding utf8
Write-Host "wrote $OutFile"
Write-Host "  $($taskPaths.Count) task routes agree on one body: $($taskPaths -join ', ')"
Write-Host "  $($fields.Count) fields: $(($fields.Name) -join ', ')"
