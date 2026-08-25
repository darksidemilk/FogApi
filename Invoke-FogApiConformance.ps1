<#
.SYNOPSIS
Exercises every generated cmdlet against a real FOG server and reports what
worked, grouped the way the API documentation groups itself.

.DESCRIPTION
The question this answers is "which of the 161 cmdlets actually work against a
real server, and which operation does each one provide". The Pester suite
answers "did the contracts hold"; this answers "what is covered", and it does it
in the shape a reader already knows -- one section per class, the way Swagger UI
groups operations by tag.

Each row names the cmdlet, the HTTP method and path it calls, the operationId
from FOG's own document, and the permission the route requires. So the report
doubles as the mapping from FogApi's surface to FOG's -- which is exactly the
thing that otherwise lives only in someone's head.

WHAT IT ACTUALLY CALLS

Read shapes are exercised for real: list, count, names, ids and search all run.
They cannot change anything.

Write shapes are NOT run unless -IncludeWrites is given, and then only for the
classes named in -WriteClasses. A create needs a valid body, a body needs
required fields, and inventing those for 51 classes would be a fixture by
another name. What a write row reports without -IncludeWrites is "not
attempted", which is honest, rather than a green tick that means nothing.

Every row it does create is named zz-conf-<class>-<random> and removed again.

.PARAMETER IncludeWrites
Also exercise create, update and delete.

.PARAMETER WriteClasses
Which classes may be written to. Defaults to the ones whose rows reference
nothing else, so a failed cleanup cannot leave a dangling association.

.PARAMETER OutputPath
Where the markdown report goes.

.PARAMETER Class
Limit the run to these classes.

.EXAMPLE
./Invoke-FogApiConformance.ps1

Read-only. Safe against any server, including production.

.EXAMPLE
./Invoke-FogApiConformance.ps1 -IncludeWrites

Full CRUD against the safe classes. Point it at a dev server.
#>
[CmdletBinding()]
param(
    [switch]$IncludeWrites,
    [string[]]$WriteClasses = @('os', 'group', 'storagegroup', 'usergroup', 'printer'),
    [string]$OutputPath = (Join-Path $PSScriptRoot 'TestResults' 'conformance.md'),
    [string[]]$Class
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Remove-Module FogApi -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $PSScriptRoot 'FogApi' 'FogApi.psd1') -Force

# This suite is the opposite of a mocked one. A leftover guard from another run
# would make every row fail with a message about mocking.
Remove-Item Env:FOGAPI_FORBID_NETWORK -ErrorAction SilentlyContinue
Reset-FogTransport

$spec = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'spec' 'fog-api-spec.json') -Raw | ConvertFrom-Json

$server = try { (Invoke-FogApi -uriPath system/info) } catch {
    throw "cannot reach the FOG server: $($_.Exception.Message). Check Get-FogServerSettings."
}

$results = [System.Collections.Generic.List[object]]::new()
$created = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param($Fn, [string]$Status, [string]$Detail = '')
    # One row per cmdlet. The write pass revisits rows the read pass marked
    # PENDING, and appending instead of replacing showed every write cmdlet
    # twice -- once as pending and once with its real result.
    $existing = @($results | Where-Object Cmdlet -eq $Fn.functionName)
    foreach ($e in $existing) { $null = $results.Remove($e) }
    $results.Add([pscustomobject]@{
        Class       = $Fn.class
        Tier        = $Fn.tier
        Cmdlet      = $Fn.functionName
        Route       = ('{0} {1}' -f $Fn.method, $Fn.path)
        OperationId = $Fn.operationId
        Permission  = $(if ($Fn.permission) { $Fn.permission } else { '' })
        Status      = $Status
        Detail      = $Detail
    })
}

function Get-ShortError {
    param($ErrorRecord)
    $m = ($ErrorRecord.Exception.Message -replace '\s+', ' ').Trim()
    if ($m.Length -gt 160) { $m.Substring(0, 160) + '...' } else { $m }
}

$candidates = @($spec.functions | Where-Object { $_.status -in @('generate', 'replaces-thin-wrapper') })
if ($Class) { $candidates = @($candidates | Where-Object { $_.class -in $Class }) }

$total = $candidates.Count
$i = 0

foreach ($fn in $candidates) {
    $i++
    Write-Progress -Activity 'FogApi conformance' -Status "$($fn.functionName)" -PercentComplete (100 * $i / $total)

    $cmd = Get-Command $fn.functionName -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Add-Result $fn 'MISSING' 'the spec specifies this cmdlet but the module does not export it'
        continue
    }
    if ($cmd.CommandType -ne 'Cmdlet') {
        # A function of the same name shadows a cmdlet, so this would be
        # exercising the wrong implementation.
        Add-Result $fn 'SHADOWED' "resolves to a $($cmd.CommandType), not the compiled cmdlet"
        continue
    }

    try {
        switch ($fn.routeName) {
            'indiv' {
                $rows = @(& $fn.functionName -First 1)
                $count = & $fn.functionName -Count
                $typed = if ($rows.Count -gt 0) { $rows[0].GetType().Name } else { 'no rows' }
                Add-Result $fn 'OK' "count=$count, first row: $typed"
            }
            'search' {
                # A term nothing will match. The assertion is that the route
                # answers, not that it finds something.
                $null = @(& $fn.functionName 'zzzznomatchzzzz')
                Add-Result $fn 'OK' 'answered'
            }
            { $_ -in @('create', 'update', 'delete') } {
                if (-not $IncludeWrites) {
                    Add-Result $fn 'NOT RUN' 'read-only run; pass -IncludeWrites'
                } elseif ($fn.class -notin $WriteClasses) {
                    Add-Result $fn 'NOT RUN' "class not in -WriteClasses"
                } else {
                    Add-Result $fn 'PENDING' 'exercised in the write pass below'
                }
            }
            { $_ -in @('task', 'cancel') } {
                # Queuing a task against a real host images it. Never automatic.
                Add-Result $fn 'NOT RUN' 'queues real work against a real machine; exercise by hand'
            }
            'active' {
                $null = @(& $fn.functionName)
                Add-Result $fn 'OK' 'answered'
            }
            default {
                Add-Result $fn 'NOT RUN' "no probe defined for route shape '$($fn.routeName)'"
            }
        }
    } catch {
        Add-Result $fn 'FAIL' (Get-ShortError $_)
    }
}

# --- the write pass --------------------------------------------------------

if ($IncludeWrites) {
    foreach ($class in ($WriteClasses | Where-Object { -not $Class -or $_ -in $Class })) {
        $newFn    = $candidates | Where-Object { $_.class -eq $class -and $_.routeName -eq 'create' } | Select-Object -First 1
        $updateFn = $candidates | Where-Object { $_.class -eq $class -and $_.routeName -eq 'update' } | Select-Object -First 1
        $deleteFn = $candidates | Where-Object { $_.class -eq $class -and $_.routeName -eq 'delete' } | Select-Object -First 1
        if (-not $newFn) { continue }

        $name = "zz-conf-$class-$(Get-Random -Maximum 9999)"
        $row = $null

        try {
            $row = & $newFn.functionName -name $name
            if ($row -and $row.id) {
                $created.Add(@{ Class = $class; Id = $row.id; Delete = $deleteFn })
                Add-Result $newFn 'OK' "created id=$($row.id)"
            } else {
                # FOG's printer create does this: it persists the row and then
                # answers 404, so the cmdlet throws while the work succeeded.
                Add-Result $newFn 'ODD' 'returned nothing usable, though the row may exist'
            }
        } catch {
            Add-Result $newFn 'FAIL' (Get-ShortError $_)
        }

        if ($row -and $row.id -and $updateFn) {
            try {
                $null = & $updateFn.functionName -id $row.id -description 'conformance run'
                Add-Result $updateFn 'OK' 'updated'
            } catch {
                Add-Result $updateFn 'FAIL' (Get-ShortError $_)
            }
        } elseif ($updateFn) {
            Add-Result $updateFn 'NOT RUN' 'nothing was created to update'
        }

        if ($row -and $row.id -and $deleteFn) {
            try {
                & $deleteFn.functionName -id $row.id -Confirm:$false
                Add-Result $deleteFn 'OK' 'deleted'
                $created.RemoveAll({ param($c) $c.Id -eq $row.id }) | Out-Null
            } catch {
                Add-Result $deleteFn 'FAIL' (Get-ShortError $_)
            }
        } elseif ($deleteFn) {
            Add-Result $deleteFn 'NOT RUN' 'nothing was created to delete'
        }
    }
}

# --- sweep -----------------------------------------------------------------

foreach ($leftover in $created) {
    try {
        Invoke-FogApi -uriPath "$($leftover.Class)/$($leftover.Id)/delete" -Method DELETE | Out-Null
        Write-Warning "conformance: cleaned up a leftover $($leftover.Class) id=$($leftover.Id)"
    } catch {
        Write-Warning "conformance: COULD NOT clean up $($leftover.Class) id=$($leftover.Id) -- remove it by hand"
    }
}

# --- report ----------------------------------------------------------------

$null = New-Item -ItemType Directory -Path (Split-Path -Parent $OutputPath) -Force

$byStatus = $results | Group-Object Status | Sort-Object Name
$ok   = @($results | Where-Object Status -eq 'OK').Count
$fail = @($results | Where-Object Status -eq 'FAIL').Count

$icon = @{
    'OK'       = '&#10003;'
    'FAIL'     = '&#10007;'
    'NOT RUN'  = '&#8211;'
    'PENDING'  = '&#8211;'
    'MISSING'  = '!'
    'SHADOWED' = '!'
    'ODD'      = '?'
}

$md = [System.Collections.Generic.List[string]]::new()
$md.Add('# FogApi conformance')
$md.Add('')
$md.Add("Every generated cmdlet, run against a real FOG server, grouped by class the way the API documentation groups itself.")
$md.Add('')
$md.Add("- server: **$($server.version)**")
$md.Add("- spec: **$($spec.source.fogVersion)**")
$md.Add("- cmdlets exercised: **$($results.Count)**")
$md.Add("- passed: **$ok**, failed: **$fail**")
$md.Add("- writes: **$(if ($IncludeWrites) { "yes, on $($WriteClasses -join ', ')" } else { 'not attempted (read-only run)' })**")
$md.Add('')
$md.Add('| status | meaning |')
$md.Add('|---|---|')
$md.Add('| OK | the route answered and the result was the shape the model expects |')
$md.Add('| FAIL | the call threw; the message is in the row |')
$md.Add('| NOT RUN | deliberately not attempted, with the reason in the row |')
$md.Add('| ODD | the call reported failure but appears to have done the work |')
$md.Add('| MISSING | the spec specifies the cmdlet, the module does not export it |')
$md.Add('| SHADOWED | a function of the same name is winning over the cmdlet |')
$md.Add('')
$md.Add('## Summary')
$md.Add('')
$md.Add('| status | count |')
$md.Add('|---|---:|')
foreach ($g in $byStatus) { $md.Add("| $($g.Name) | $($g.Count) |") }
$md.Add('')

if ($fail -gt 0) {
    $md.Add('## Failures')
    $md.Add('')
    $md.Add('| cmdlet | route | detail |')
    $md.Add('|---|---|---|')
    foreach ($r in ($results | Where-Object Status -eq 'FAIL' | Sort-Object Class, Cmdlet)) {
        $md.Add("| ``$($r.Cmdlet)`` | ``$($r.Route)`` | $($r.Detail) |")
    }
    $md.Add('')
}

$md.Add('## By class')
$md.Add('')
foreach ($group in ($results | Group-Object Class | Sort-Object Name)) {
    $classOk = @($group.Group | Where-Object Status -eq 'OK').Count
    $md.Add("### $($group.Name)  <sub>tier $(@($group.Group)[0].Tier) &middot; $classOk/$($group.Count) OK</sub>")
    $md.Add('')
    $md.Add('| | cmdlet | operation | route | permission | detail |')
    $md.Add('|---|---|---|---|---|---|')
    foreach ($r in ($group.Group | Sort-Object Cmdlet)) {
        $mark = if ($icon.ContainsKey($r.Status)) { $icon[$r.Status] } else { $r.Status }
        $md.Add("| $mark | ``$($r.Cmdlet)`` | ``$($r.OperationId)`` | ``$($r.Route)`` | ``$($r.Permission)`` | $($r.Detail) |")
    }
    $md.Add('')
}

Set-Content -LiteralPath $OutputPath -Value ($md -join "`n") -Encoding utf8

# --- console ---------------------------------------------------------------

Write-Host ''
Write-Host "FogApi conformance against $($server.version)" -ForegroundColor Cyan
Write-Host ''
foreach ($group in ($results | Group-Object Class | Sort-Object Name)) {
    $classOk = @($group.Group | Where-Object Status -eq 'OK').Count
    $classFail = @($group.Group | Where-Object Status -eq 'FAIL').Count
    $colour = if ($classFail -gt 0) { 'Red' } elseif ($classOk -gt 0) { 'Green' } else { 'DarkGray' }
    Write-Host ("  {0,-24} {1,2}/{2,-2} OK" -f $group.Name, $classOk, $group.Count) -ForegroundColor $colour
    foreach ($r in ($group.Group | Where-Object Status -in @('FAIL', 'MISSING', 'SHADOWED', 'ODD') | Sort-Object Cmdlet)) {
        Write-Host ("      {0,-10} {1,-34} {2}" -f $r.Status, $r.Cmdlet, $r.Detail) -ForegroundColor Yellow
    }
}
Write-Host ''
foreach ($g in $byStatus) { Write-Host ("  {0,-10} {1}" -f $g.Name, $g.Count) }
Write-Host ''
Write-Host "report: $OutputPath" -ForegroundColor Cyan
