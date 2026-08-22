#Requires -Version 5.1
<#
.SYNOPSIS
Writes docs/ApiCoverage.md: every operation FOG serves, and what FogApi offers
for it.

.DESCRIPTION
The point of this report is the denominator. "66 public functions" says nothing
about coverage; "FOG 1.6 serves 554 operations across 52 classes" turns coverage
into a number that can go up.

Four states per operation, and the distinction between the last two is the one
that matters:

  covered       a typed cmdlet exists today (hand-written or a thin wrapper)
  planned       the spec says a cmdlet will be generated for it
  folded        deliberately a parameter on another cmdlet rather than its own
                cmdlet -- count, names, ids and join
  L1-only       reachable only as Get-FogObject -type object -coreObject <x>.
                Not a bug and not necessarily a gap: nobody wants a typed
                cmdlet for every write verb on every lookup table. It is the
                honest residual, and it is what the tiers are chosen against.

Reads spec/fog-api-spec.json, so it reports what the spec actually resolved to
rather than what anyone intended.

.PARAMETER SpecFile
Path to the resolved spec. Defaults to spec/fog-api-spec.json.

.PARAMETER OutFile
Where to write the report. Defaults to docs/ApiCoverage.md.

.EXAMPLE
./spec/tools/Get-FogApiCoverage.ps1

Regenerates docs/ApiCoverage.md.
#>
[CmdletBinding()]
param (
    [string]$SpecFile,
    [string]$OutFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$specRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$repoRoot = Split-Path -Parent $specRoot
if (-not $SpecFile) { $SpecFile = Join-Path $specRoot 'fog-api-spec.json' }
if (-not $OutFile)  { $OutFile  = Join-Path (Join-Path $repoRoot 'docs') 'ApiCoverage.md' }

if (-not (Test-Path -LiteralPath $SpecFile)) {
    throw "Spec not found at $SpecFile. Run spec/tools/Build-FogApiSpec.ps1 first."
}
$spec = Get-Content -LiteralPath $SpecFile -Raw | ConvertFrom-Json

$foldedRoutes = @($spec.folded.PSObject.Properties.Name | Where-Object { $_ -notlike '$*' })

# operationId -> the function that answers for it
$answeredBy = @{}
foreach ($fn in $spec.functions) {
    if ($fn.status -eq 'skipped-name-taken') {
        # A hand-written function owns the name, which means it also owns the
        # operation -- Get-FogHost over host/indiv, for instance.
        $answeredBy[$fn.operationId] = [pscustomobject]@{ name = $fn.functionName; state = 'covered' }
    } elseif ($fn.status -eq 'replaces-thin-wrapper') {
        $answeredBy[$fn.operationId] = [pscustomobject]@{ name = "$($fn.replaces) -> $($fn.functionName)"; state = 'covered' }
    } else {
        $answeredBy[$fn.operationId] = [pscustomobject]@{ name = $fn.functionName; state = 'planned' }
    }
}
foreach ($fx in $spec.fixedRoutes) {
    $state = if ($fx.existing) { 'covered' } else { 'planned' }
    $name = if ($fx.existing -and $fx.existing -ne $fx.functionName) { "$($fx.existing) -> $($fx.functionName)" } else { $fx.functionName }
    $answeredBy[$fx.operationId] = [pscustomobject]@{ name = $name; state = $state }
}

# Rebuild the full operation list from the schemas plus the spec's own class
# view. Everything not answered above is folded or L1-only.
$classes = @($spec.schemas.PSObject.Properties.Name | Sort-Object)
$genericRoutes = @('list', 'indiv', 'create', 'update', 'delete', 'search', 'count', 'names', 'ids', 'join', 'task', 'cancel', 'active')

$tierOf = @{}
foreach ($fn in $spec.functions) { $tierOf[$fn.class] = $fn.tier }

$rows = [System.Collections.Generic.List[object]]::new()
$totals = @{ covered = 0; planned = 0; folded = 0; l1 = 0 }

foreach ($class in $classes) {
    $classFns = @($spec.functions | Where-Object { $_.class -eq $class })
    $known = @{}
    foreach ($fn in $classFns) { $known[$fn.routeName] = $fn }

    $cells = [ordered]@{}
    foreach ($route in $genericRoutes) {
        $opId = $route + $class.Substring(0,1).ToUpperInvariant() + $class.Substring(1)
        # Only score routes the server actually serves for this class.
        $served = $false
        if ($known.ContainsKey($route)) { $served = $true }
        elseif ($foldedRoutes -contains $route) { $served = $true }
        elseif ($route -in @('task','cancel','active')) { $served = $false }
        else { $served = $true }

        if (-not $served) { $cells[$route] = ''; continue }

        if ($answeredBy.ContainsKey($opId)) {
            $a = $answeredBy[$opId]
            $cells[$route] = if ($a.state -eq 'covered') { 'x' } else { 'o' }
            $totals[$a.state] += 1
        } elseif ($foldedRoutes -contains $route) {
            $cells[$route] = 'f'
            $totals.folded += 1
        } else {
            $cells[$route] = '-'
            $totals.l1 += 1
        }
    }
    $rows.Add([pscustomobject]@{ class = $class; tier = $(if ($tierOf.ContainsKey($class)) { $tierOf[$class] } else { '?' }); cells = $cells })
}

$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine('# API coverage')
$null = $sb.AppendLine()
$null = $sb.AppendLine('<!-- GENERATED by spec/tools/Get-FogApiCoverage.ps1. Do not edit. -->')
$null = $sb.AppendLine()
$null = $sb.AppendLine(("FOG {0} serves **{1} operations** across **{2} route classes**. This is what FogApi offers for each of them." -f `
    $spec.source.fogVersion, $spec.stats.snapshotOperations, $spec.stats.snapshotClasses))
$null = $sb.AppendLine()
$null = $sb.AppendLine('Generated from `spec/fog-api-spec.json`, which is itself built from FOG''s own OpenAPI document. Rebuild with `spec/tools/Build-FogApiSpec.ps1` then this script.')
$null = $sb.AppendLine()
$null = $sb.AppendLine('| Key | Meaning |')
$null = $sb.AppendLine('|---|---|')
$null = $sb.AppendLine('| `x` | A typed cmdlet exists today. |')
$null = $sb.AppendLine('| `o` | A typed cmdlet is specified and will be generated. |')
$null = $sb.AppendLine('| `f` | Folded: a parameter on another cmdlet rather than a cmdlet of its own. |')
$null = $sb.AppendLine('| `-` | Reachable only through the generic L1 wrappers. |')
$null = $sb.AppendLine('| (blank) | The server does not serve this operation for this class. |')
$null = $sb.AppendLine()
$null = $sb.AppendLine(('**Totals:** {0} covered, {1} specified, {2} folded, {3} L1-only.' -f `
    $totals.covered, $totals.planned, $totals.folded, $totals.l1))
$null = $sb.AppendLine()
$null = $sb.AppendLine('## Per-class operations')
$null = $sb.AppendLine()
$null = $sb.AppendLine('| Class | Tier | ' + (($genericRoutes | ForEach-Object { '`' + $_ + '`' }) -join ' | ') + ' |')
$null = $sb.AppendLine('|---|---|' + (($genericRoutes | ForEach-Object { '---' }) -join '|') + '|')
foreach ($row in $rows) {
    $cellText = @($genericRoutes | ForEach-Object { $row.cells[$_] })
    $null = $sb.AppendLine(('| `{0}` | {1} | {2} |' -f $row.class, $row.tier, ($cellText -join ' | ')))
}

$null = $sb.AppendLine()
$null = $sb.AppendLine('## Fixed routes')
$null = $sb.AppendLine()
$null = $sb.AppendLine('Endpoints with no class shape, so no L1 representation. These are the only cmdlets allowed to call `Invoke-FogApi` directly.')
$null = $sb.AppendLine()
$null = $sb.AppendLine('| Operation | Method | Path | Cmdlet | State | Note |')
$null = $sb.AppendLine('|---|---|---|---|---|---|')
foreach ($fx in ($spec.fixedRoutes | Sort-Object operationId)) {
    $state = if ($fx.existing) { 'covered' } else { 'specified' }
    $existing = if ($fx.existing -and $fx.existing -ne $fx.functionName) { "was ``$($fx.existing)``. " } else { '' }
    $note = ($existing + $(if ($fx.note) { $fx.note } else { '' })).Trim()
    $null = $sb.AppendLine(('| `{0}` | {1} | `{2}` | `{3}` | {4} | {5} |' -f `
        $fx.operationId, $fx.method, $fx.path, $fx.functionName, $state, $note))
}

$null = $sb.AppendLine()
$null = $sb.AppendLine('## Hand-written functions')
$null = $sb.AppendLine()
$null = $sb.AppendLine('Registered rather than generated, so they read as covered rather than as gaps, and so the Python and bash emitters know which ones they owe. `workflow` functions carry version branching, join-table reconciliation or multi-call orchestration; generating those would mean generating judgement.')
$null = $sb.AppendLine()
$null = $sb.AppendLine('| Function | Category | Platform | Ports owed | Note |')
$null = $sb.AppendLine('|---|---|---|---|---|')
foreach ($name in (@($spec.handWritten.PSObject.Properties.Name | Where-Object { $_ -notlike '$*' }) | Sort-Object)) {
    $e = $spec.handWritten.$name
    $targets = if ($e.targets.Count -gt 0) { ($e.targets -join ', ') } else { 'none' }
    $note = if ($e.PSObject.Properties.Name -contains 'note') { $e.note } else { '' }
    $null = $sb.AppendLine(('| `{0}` | {1} | {2} | {3} | {4} |' -f $name, $e.category, $e.platform, $targets, $note))
}

$null = $sb.AppendLine()
$null = $sb.AppendLine('## FOG 1.5')
$null = $sb.AppendLine()
$null = $sb.AppendLine('No spec exists for the 1.5 line: it ships no `commons/schema-expected.php`, so nothing describes its types. The deltas below are hand-recorded in `spec/overlay/fog-api-overlay.json` and are what every generated cmdlet branches on.')
$null = $sb.AppendLine()
$null = $sb.AppendLine(('- **Envelope:** {0}' -f $spec.fifteen.envelope))
$null = $sb.AppendLine(('- **Paging:** {0}' -f $spec.fifteen.paging))
$null = $sb.AppendLine(('- **Operations 1.5 does not have:** {0}' -f (($spec.fifteen.absentOperations | ForEach-Object { '`' + $_ + '`' }) -join ', ')))
$null = $sb.AppendLine(('- **Classes 1.5 does not have:** {0}' -f (($spec.fifteen.absentClasses.classes | ForEach-Object { '`' + $_ + '`' }) -join ', ')))

$dir = Split-Path -Parent $OutFile
if (-not (Test-Path -LiteralPath $dir)) { $null = New-Item -ItemType Directory -Path $dir -Force }
Set-Content -LiteralPath $OutFile -Value $sb.ToString() -Encoding utf8

Write-Host "wrote $OutFile"
Write-Host ("  {0} covered, {1} specified, {2} folded, {3} L1-only" -f $totals.covered, $totals.planned, $totals.folded, $totals.l1)
