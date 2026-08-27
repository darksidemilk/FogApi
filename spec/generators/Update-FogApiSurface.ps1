#Requires -Version 7.0
<#
.SYNOPSIS
    Records, or checks, the module's public cmdlet surface.

.DESCRIPTION
    The generated client is not committed (see .gitignore), so a regeneration can
    rename, add or drop a public cmdlet without changing a single tracked file.
    Nobody would see it in a pull request; it would surface after release.

    This script is what replaces that lost reviewability. It walks the generated
    cmdlets and writes one line per exported cmdlet and parameter into
    spec/generators/surface.txt -- a small, readable, diffable artifact that IS
    committed. CI runs it with -Check, and a difference fails the build until the
    snapshot is updated in the same pull request.

    The snapshot deliberately records parameter names, not just cmdlet names. A
    dropped parameter is as breaking as a dropped cmdlet and is far easier to
    introduce by accident -- a schema field losing its type upstream is enough.

    Runtime plumbing that AutoRest adds to every cmdlet (Break, HttpPipeline*,
    Proxy*) is excluded: it is identical everywhere, would treble the file, and
    changes only when the generator version changes -- which is pinned and
    tracked separately.

.PARAMETER GeneratedRoot
    The AutoRest output folder. Defaults to ./out beside this script.

.PARAMETER Path
    The snapshot file. Defaults to ./surface.txt beside this script.

.PARAMETER Check
    Compare instead of write. Exits non-zero and prints a diff on any change.

.EXAMPLE
    ./Update-FogApiSurface.ps1
    Regenerates the snapshot after an intended surface change.

.EXAMPLE
    ./Update-FogApiSurface.ps1 -Check
    The CI gate. Fails if the generated surface no longer matches the snapshot.
#>
[CmdletBinding()]
param(
    [string]$GeneratedRoot = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'FogApi-clients/pwsh/src'),
    [string]$Path = (Join-Path $PSScriptRoot 'surface.txt'),
    [switch]$Check
)

$ErrorActionPreference = 'Stop'

$cmdletDir = Join-Path $GeneratedRoot 'generated/cmdlets'
if (-not (Test-Path -LiteralPath $cmdletDir)) {
    throw "No generated cmdlets at $cmdletDir. Run Invoke-FogApiGeneration.ps1 first."
}

# Plumbing AutoRest attaches to every cmdlet. Excluded so the snapshot describes
# this API rather than the generator.
$plumbing = @(
    'Break', 'HttpPipelineAppend', 'HttpPipelinePrepend',
    'Proxy', 'ProxyCredential', 'ProxyUseDefaultCredentials'
)

$surface = [System.Collections.Generic.SortedDictionary[string, object]]::new()

foreach ($file in Get-ChildItem -LiteralPath $cmdletDir -Filter '*.cs') {
    $src = Get-Content -LiteralPath $file.FullName -Raw

    # [Cmdlet(VerbsCommon.Get, @"FogHost_List")] -- trailing named arguments
    # such as SupportsShouldProcess must not break the match, which is what
    # every mutating cmdlet carries.
    $m = [regex]::Match(
        $src,
        'Cmdlet\(\s*(?:global::System\.Management\.Automation\.)?(?:Verbs\w+\.(\w+)|@?"([^"]+)")\s*,\s*@?"([^"]+)"'
    )
    if (-not $m.Success) { continue }

    $verb = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
    # Strip the _ParameterSetVariant suffix; build-module.ps1 collapses those
    # into one exported proxy, so they are not distinct surface.
    $noun = $m.Groups[3].Value -replace '_.*$', ''
    $name = "$verb-$noun"

    if (-not $surface.ContainsKey($name)) {
        $surface[$name] = [ordered]@{
            Parameters = [System.Collections.Generic.SortedSet[string]]::new()
            OutputType = [System.Collections.Generic.SortedSet[string]]::new()
        }
    }

    # Parameters are the properties carrying a Parameter attribute. Body-backed
    # ones are expression-bodied (`{ get => _body.Name ... }`), so a pattern
    # requiring `{ get;` silently misses every expanded body field -- which is
    # most of the interesting surface.
    foreach ($pm in [regex]::Matches(
            $src,
            '(?s)Automation\.Parameter\((?<attr>[^)]*)\).*?public\s+[^\s]+\s+(?<prop>[A-Za-z0-9_]+)\s*\{')) {
        $prop = $pm.Groups['prop'].Value
        if ($prop -in $plumbing) { continue }
        $mandatory = $pm.Groups['attr'].Value -match 'Mandatory\s*=\s*true'
        $surface[$name].Parameters.Add($(if ($mandatory) { "$prop*" } else { $prop })) | Out-Null
    }

    foreach ($om in [regex]::Matches($src, 'OutputType\(typeof\(([^)]+)\)')) {
        $surface[$name].OutputType.Add(
            ($om.Groups[1].Value -replace '^FogApi\.Models\.', '')) | Out-Null
    }
}

$lines = foreach ($name in $surface.Keys) {
    $e = $surface[$name]
    "{0} -> {1}" -f $name, (($e.OutputType) -join ', ')
    foreach ($p in $e.Parameters) { "    -$p" }
}

$header = @(
    '# FogApi public surface -- GENERATED, do not hand-edit.'
    '#'
    '# Regenerate with spec/generators/Update-FogApiSurface.ps1 whenever a'
    '# surface change is intended, in the same commit as the change. CI runs'
    '# -Check and fails on any difference, because the generated client is not'
    '# committed and this file is the only place a rename or a dropped'
    '# parameter becomes visible in review.'
    '#'
    '# A trailing * marks a mandatory parameter. Generator plumbing'
    '# (Break, HttpPipeline*, Proxy*) is excluded.'
    ''
    "# cmdlets: $($surface.Count)"
    ''
)

$content = (($header + $lines) -join "`n") + "`n"

if (-not $Check) {
    Set-Content -LiteralPath $Path -Value $content -NoNewline -Encoding utf8
    Write-Host "wrote $Path -- $($surface.Count) cmdlets" -ForegroundColor Green
    return
}

if (-not (Test-Path -LiteralPath $Path)) {
    throw "No surface snapshot at $Path. Run without -Check to create it."
}

$existing = Get-Content -LiteralPath $Path -Raw
if ($existing -eq $content) {
    Write-Host "surface matches snapshot -- $($surface.Count) cmdlets" -ForegroundColor Green
    return
}

# Show what moved, not the whole file.
$old = ($existing -split "`r?`n") | Where-Object { $_ -notmatch '^#' -and $_ -ne '' }
$new = ($content  -split "`r?`n") | Where-Object { $_ -notmatch '^#' -and $_ -ne '' }
$diff = Compare-Object -ReferenceObject $old -DifferenceObject $new

Write-Host 'The generated surface no longer matches the committed snapshot.' -ForegroundColor Red
Write-Host ''
foreach ($d in $diff) {
    $sigil = if ($d.SideIndicator -eq '=>') { '+' } else { '-' }
    $colour = if ($d.SideIndicator -eq '=>') { 'Green' } else { 'Red' }
    Write-Host "  $sigil $($d.InputObject)" -ForegroundColor $colour
}
Write-Host ''
Write-Host 'If this change is intended, run spec/generators/Update-FogApiSurface.ps1' -ForegroundColor Yellow
Write-Host 'and commit the updated snapshot alongside it.' -ForegroundColor Yellow

exit 1
