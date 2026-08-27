#Requires -Version 7.0
<#
.SYNOPSIS
    Generates the FogApi client from FOG's OpenAPI document with AutoRest.

.DESCRIPTION
    One command, pinned versions, and the gate checked automatically.

    This exists because the generated surface is NOT committed (see the note in
    .gitignore). That makes the generator invocation the only description of what
    ships, so it has to be a tracked file rather than a remembered command line.
    An unpinned `npx autorest` can change every exported cmdlet without changing
    anything under version control.

    Two things are asserted, because both have silently produced a useless run
    before:

    - The input document's operationIds must carry an underscore. Every
      generator splits operationId on `_` to find the verb; FOG's ids had no
      underscore until FOGProject/fogproject#1373, so the verb lookup fell back
      to guessing and warned once per operation. A pre-#1373 document generates
      0 Get- cmdlets and 225 Invoke- ones. Checked before the run, because the
      run costs ~150 seconds.

    - The log must contain zero "inferred without finding action" warnings.
      That count IS the pass/fail gate -- it was one-per-operation for weeks and
      nobody read the log. Checked after the run, and a non-zero count is a
      terminating error rather than a warning.

.PARAMETER OutputFolder
    Where to write the generated module. Defaults to FogApi-clients/pwsh/src,
    which .gitignore excludes.

.PARAMETER InputFile
    Override the document. Defaults to whatever autorest-readme.md declares
    (the committed snapshot). Use this to generate against a live server's
    document, which is the only way plugin classes appear.

.PARAMETER SkipInputCheck
    Skip the operationId assertion. Only useful for deliberately reproducing a
    pre-#1373 result.

.PARAMETER UpdateWarningBaseline
    Record the run's warning counts in warning-baseline.json instead of
    checking against it. Use when a change to the document or the config
    legitimately moves a count, and say why in the commit message.

.EXAMPLE
    ./Invoke-FogApiGeneration.ps1
    Generates from the committed snapshot and reports the surface.

.EXAMPLE
    ./Invoke-FogApiGeneration.ps1 -InputFile ~/fog-live.json
    Generates from a live-server document, which includes plugin classes.
#>
[CmdletBinding()]
param(
    [string]$OutputFolder = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'FogApi-clients/pwsh/src'),
    [string]$InputFile,
    [switch]$SkipInputCheck,
    [switch]$UpdateWarningBaseline
)

$ErrorActionPreference = 'Stop'

# Pinned deliberately. The core version is the `--version:` argument, NOT an
# npm version of the `autorest` CLI package -- `npx autorest@3.10.9` fails with
# ETARGET, because 3.10.9 is @autorest/core.
$AutorestCore = '3.10.9'
$PowerShellGenerator = '@autorest/powershell@4.0.758'

$readme = Join-Path $PSScriptRoot 'autorest-readme.md'
if (-not (Test-Path -LiteralPath $readme)) {
    throw "AutoRest config not found: $readme"
}

# Resolve the document the same way AutoRest will, so the check below inspects
# what the run will actually consume.
$document = if ($InputFile) {
    $InputFile
} else {
    $declared = (Select-String -LiteralPath $readme -Pattern '^\s*input-file:\s*(\S+)' |
        Select-Object -First 1).Matches.Groups[1].Value
    if (-not $declared) { throw "autorest-readme.md declares no input-file" }
    Join-Path $PSScriptRoot $declared
}

if (-not (Test-Path -LiteralPath $document)) {
    throw "Input document not found: $document"
}
$document = (Resolve-Path -LiteralPath $document).Path

if (-not $SkipInputCheck) {
    Write-Verbose "Checking operationIds in $document"
    $doc = Get-Content -LiteralPath $document -Raw | ConvertFrom-Json -AsHashtable
    $ids = foreach ($pathItem in $doc.paths.Values) {
        foreach ($op in $pathItem.Values) {
            if ($op -is [hashtable] -and $op.ContainsKey('operationId')) { $op.operationId }
        }
    }
    $withUnderscore = @($ids).Where{ $_ -like '*_*' }.Count
    $total = @($ids).Count
    if ($total -eq 0) { throw "No operationIds found in $document -- not an OpenAPI document?" }
    if ($withUnderscore -ne $total) {
        throw @"
$($total - $withUnderscore) of $total operationIds carry no underscore, e.g. $(@($ids).Where({ $_ -notlike '*_*' })[0]).

Every generator splits operationId on '_' to find the verb. Generating from
this document produces 0 Get- cmdlets and one inference warning per operation.
Re-dump from a checkout that includes FOGProject/fogproject#1373:

  php spec/tools/dump-openapi.php --web <fogproject>/packages/web --out spec/openapi/fog-1.6.json

Pass -SkipInputCheck to generate anyway.
"@
    }
    Write-Host "input:  $total operations, all carrying the verb underscore" -ForegroundColor DarkGray
}

$log = Join-Path ([System.IO.Path]::GetTempPath()) "fogapi-autorest-$PID.log"

Write-Host "autorest core $AutorestCore, $PowerShellGenerator" -ForegroundColor DarkGray
Write-Host "output: $OutputFolder" -ForegroundColor DarkGray

# AutoRest APPENDS a command-line --input-file to the one the readme declares
# rather than replacing it. Passing both makes it ingest the same document
# twice: 1,888 cmdlet files instead of 944, every cmdlet duplicated, and a run
# that takes 764s instead of ~150s -- and it still exits 0, so nothing catches
# it but the count.
#
# So the document is always substituted into a temporary copy of the readme and
# --input-file is never passed. That keeps -InputFile working as an override
# rather than an addition, and keeps one code path for both cases.
$runReadme = Join-Path ([System.IO.Path]::GetTempPath()) "fogapi-autorest-$PID-readme.md"
(Get-Content -LiteralPath $readme -Raw) -replace
    '(?m)^\s*input-file:.*$', "input-file: $($document -replace '\\', '/')" |
    Set-Content -LiteralPath $runReadme -Encoding utf8

try {
    # --clear-output-folder because the surface is not committed: a stale file
    # left by a previous run would ship as though it had been generated.
    & npx -y autorest "--version:$AutorestCore" --powershell `
        "--use:$PowerShellGenerator" $runReadme `
        "--output-folder=$OutputFolder" --clear-output-folder `
        *>&1 | Tee-Object -FilePath $log
} finally {
    Remove-Item -LiteralPath $runReadme -ErrorAction SilentlyContinue
}

if ($LASTEXITCODE -ne 0) {
    throw "AutoRest failed with exit code $LASTEXITCODE. Log: $log"
}

# Strip ANSI once, and read the log through it from here on. AutoRest colours
# its output, and whether those escapes reach the log depends on how pwsh was
# invoked -- a direct run wrote plain text, the same command under make.ps1
# wrote `<esc>[33m<esc>[1mwarning<esc>[22m<esc>[39m | <esc>[32mModeler/...`.
# Any pattern spanning a coloured boundary silently stops matching, and a gate
# that silently stops matching reads as a pass.
$plain = (Get-Content -LiteralPath $log -Raw) -replace '\x1b\[[0-9;]*m', ''

# The gate.
$inferred = [regex]::Matches($plain, 'inferred without finding action').Count
if ($inferred -ne 0) {
    throw @"
$inferred operations had their verb inferred rather than read from the
operationId. That is the pass/fail gate for this generator and it must be 0.
Log: $log
"@
}

# The second gate: every other warning, counted by class.
#
# The check above greps for one string. The run also prints ~145 warnings the
# grep never sees, and that is exactly how the operationId defect survived --
# it warned once per operation for weeks and nobody read the log. Counting the
# rest keeps them on screen while making any change loud.
$observed = @{}
foreach ($match in [regex]::Matches($plain, 'warning \| ([A-Za-z/]+)')) {
    $class = $match.Groups[1].Value
    $observed[$class] = 1 + ($observed[$class] ?? 0)
}

$baselineFile = Join-Path $PSScriptRoot 'warning-baseline.json'

if ($UpdateWarningBaseline) {
    if (-not (Test-Path -LiteralPath $baselineFile)) {
        throw "No baseline at $baselineFile to update."
    }
    $baseline = Get-Content -LiteralPath $baselineFile -Raw | ConvertFrom-Json
    foreach ($class in $observed.Keys) {
        if ($baseline.classes.PSObject.Properties.Name -contains $class) {
            $baseline.classes.$class.count = $observed[$class]
        } else {
            $baseline.classes | Add-Member -NotePropertyName $class -NotePropertyValue ([pscustomobject]@{
                count = $observed[$class]
                why   = 'TODO: explain why this warning is expected, or fix it.'
            })
        }
    }
    # Drop classes that no longer occur, so the baseline cannot rot upward.
    foreach ($class in @($baseline.classes.PSObject.Properties.Name)) {
        if (-not $observed.ContainsKey($class)) {
            $baseline.classes.PSObject.Properties.Remove($class)
        }
    }
    $baseline.documentVersion = (Get-Content -LiteralPath $document -Raw |
        ConvertFrom-Json).info.version
    $baseline | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $baselineFile -Encoding utf8
    Write-Host "warning baseline updated: $baselineFile" -ForegroundColor Yellow
    Write-Host '  say in the commit message why each number moved.' -ForegroundColor Yellow

} elseif (Test-Path -LiteralPath $baselineFile) {
    $baseline = Get-Content -LiteralPath $baselineFile -Raw | ConvertFrom-Json
    $expectedDoc = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../openapi/fog-1.6.json')).Path
    $isSnapshot = $document -eq $expectedDoc

    $drift = @()
    foreach ($class in ($observed.Keys + $baseline.classes.PSObject.Properties.Name | Sort-Object -Unique)) {
        $was = if ($baseline.classes.PSObject.Properties.Name -contains $class) {
            $baseline.classes.$class.count
        } else { 0 }
        $now = $observed[$class] ?? 0
        if ($was -ne $now) { $drift += "  $class : $was -> $now" }
    }

    if ($drift.Count -eq 0) {
        Write-Host "warnings: unchanged from baseline ($(($observed.Values | Measure-Object -Sum).Sum) across $($observed.Count) classes)" -ForegroundColor DarkGray
    } elseif (-not $isSnapshot) {
        # A live or checkout document carries whatever classes that server has,
        # so different counts are expected rather than wrong.
        Write-Host 'warnings differ from the baseline, which records the committed snapshot:' -ForegroundColor DarkGray
        $drift | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
        Write-Host '  not enforced -- this document is not the committed snapshot.' -ForegroundColor DarkGray
    } else {
        throw @"
The generator's warnings changed against the committed snapshot:

$($drift -join "`n")

Every warning in the baseline is there with a reason. A change means either
something regressed, or something was fixed, or the generator started saying
something new -- all three are worth a look rather than a scroll.

Read them:  Select-String -Path '$log' -Pattern 'warning \|'
Accept them: re-run with -UpdateWarningBaseline, and say why in the commit.
"@
    }
}

$cmdletDir = Join-Path $OutputFolder 'generated/cmdlets'
$files = @(Get-ChildItem -LiteralPath $cmdletDir -Filter '*.cs' -ErrorAction SilentlyContinue)

# Distinct exported names, not source files. AutoRest emits one file per
# parameter-set variant (_Create, _CreateExpanded, _CreateViaIdentity), which
# build-module.ps1 collapses into a single exported proxy -- so a file count
# roughly doubles the real surface and is not what a user sees.
# Split on the configured prefix rather than on "leading run of lowercase".
# GetFogHost_List -> Get + FogHost. A pattern like ^([A-Z][a-z]+)(.+?)_ looks
# right and is not: the lazy noun lets the verb group creep, and the names come
# out as ExportFogSyste-m. The prefix is the one reliable boundary in the name,
# and this script is what sets it.
$prefix = 'Fog'
$names = $files | ForEach-Object {
    # $_.BaseName, not $_ -- matching the FileInfo coerces it to a full path,
    # which never matches an anchored pattern, and the count is a silent 0.
    if ($_.BaseName -match "^(?<verb>[A-Za-z]+?)$prefix(?<noun>[^_]*)") {
        "$($Matches.verb)-$prefix$($Matches.noun)"
    }
} | Sort-Object -Unique

if ($files.Count -gt 0 -and $names.Count -eq 0) {
    throw "Parsed 0 cmdlet names from $($files.Count) source files -- the name pattern no longer matches AutoRest's filenames."
}
# One name per two source files is the expected ratio (AutoRest emits a file per
# parameter-set variant). Far more names than that means the split is wrong;
# far fewer means the document was ingested twice.
if ($files.Count -gt 0 -and ($files.Count / [math]::Max($names.Count, 1)) -gt 4) {
    Write-Warning "$($files.Count) source files for only $($names.Count) names -- was the document ingested twice?"
}

$unprefixed = @($names).Where{ $_ -notmatch '^[A-Za-z]+-Fog' }

Write-Host ''
Write-Host "inference warnings:      $inferred" -ForegroundColor Green
Write-Host "generated source files:  $($files.Count)"
Write-Host "distinct cmdlet names:   $($names.Count)"
Write-Host "without a Fog prefix:    $($unprefixed.Count)" -ForegroundColor $(if ($unprefixed.Count) { 'Red' } else { 'Green' })
if ($unprefixed.Count) { Write-Host "  $($unprefixed -join ', ')" -ForegroundColor Red }

Write-Host ''
Write-Host 'by verb:'
$names | Group-Object { ($_ -split '-')[0] } | Sort-Object Count -Descending |
    ForEach-Object { '  {0,-10} {1}' -f $_.Name, $_.Count }

[pscustomobject]@{
    Document          = $document
    OutputFolder      = $OutputFolder
    Log               = $log
    InferenceWarnings = $inferred
    SourceFiles       = $files.Count
    CmdletNames       = $names.Count
    Names             = $names
}
