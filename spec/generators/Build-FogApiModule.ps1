#Requires -Version 7.0
<#
.SYNOPSIS
    Dumps FOG's document, generates the client, builds it, and imports it.

.DESCRIPTION
    One command from a fogproject checkout to an imported module. It wraps
    three steps that each have a way of failing quietly:

    1. dump-openapi.php     -- produces the OpenAPI document from a checkout,
                               no server and no database needed
    2. Invoke-FogApiGeneration.ps1 -- runs AutoRest with pinned versions and
                               asserts the operationId and warning gates
    3. build-module.ps1     -- AutoRest's own script: compiles the C# and
                               exports the PowerShell proxies

    Step 3 is the one to watch. **build-module.ps1 exits 0 even when
    compilation fails** -- it calls Write-Error and returns success -- so this
    script checks for the artifacts it should have produced rather than
    trusting the exit code. That is not hypothetical: the first ever attempt
    to build this module failed with 333 compile errors and reported success.

.PARAMETER Web
    Path to a fogproject checkout's packages/web. When given, the document is
    dumped fresh from it. Omit to use the committed snapshot in
    spec/openapi/fog-1.6.json.

    The committed snapshot builds as it stands. Pass -Web to pick up upstream
    changes newer than it, or to generate against a checkout of your own.

.PARAMETER OutputFolder
    Where to generate and build. Defaults to FogApi-clients/pwsh/src, which
    .gitignore excludes.

.PARAMETER Import
    Import the built module and report the command count.

.PARAMETER SkipGenerate
    Reuse whatever is already generated and only run the build. Useful when
    iterating on build-module.ps1 itself.

.EXAMPLE
    ./Build-FogApiModule.ps1 -Web C:\Users\me\git\working-1.6\packages\web -Import

    Dump, generate, build and import in one go. This is the usual invocation.

.EXAMPLE
    ./Build-FogApiModule.ps1 -Import

    Same, from the committed snapshot. Verified: 474 commands imported.

.EXAMPLE
    Import-Module ./FogApi-clients/pwsh/src/FogApi.psd1
    Get-Command -Module FogApi | Measure-Object

    What -Import does, by hand, afterwards.
#>
[CmdletBinding()]
param(
    [string]$Web,
    [string]$OutputFolder = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'FogApi-clients/pwsh/src'),
    [switch]$Import,
    [switch]$SkipGenerate
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

function Write-Step($n, $text) {
    Write-Host ''
    Write-Host "[$n] $text" -ForegroundColor Cyan
}

# --- 1. the document ---------------------------------------------------
$document = Join-Path $repoRoot 'spec/openapi/fog-1.6.json'

if ($Web) {
    Write-Step 1 "Dumping the document from $Web"
    if (-not (Test-Path -LiteralPath (Join-Path $Web 'lib/fog'))) {
        throw "Not a packages/web directory (no lib/fog): $Web"
    }
    if (-not (Get-Command php -ErrorAction SilentlyContinue)) {
        throw 'php is not on PATH. The dumper needs it; no server or database is required.'
    }
    $document = Join-Path ([System.IO.Path]::GetTempPath()) "fog-openapi-$PID.json"
    & php (Join-Path $repoRoot 'spec/tools/dump-openapi.php') --web $Web --out $document
    if ($LASTEXITCODE -ne 0) { throw "dump-openapi.php failed with exit code $LASTEXITCODE" }
} else {
    Write-Step 1 'Using the committed snapshot'
    Write-Host "    $document" -ForegroundColor DarkGray
}

# --- 2. generate -------------------------------------------------------
if (-not $SkipGenerate) {
    Write-Step 2 'Generating with AutoRest (pinned; takes a few minutes)'
    & (Join-Path $PSScriptRoot 'Invoke-FogApiGeneration.ps1') `
        -InputFile $document -OutputFolder $OutputFolder | Out-Host
} else {
    Write-Step 2 'Skipping generation (-SkipGenerate)'
}

# --- 3. build ----------------------------------------------------------
$buildScript = Join-Path $OutputFolder 'build-module.ps1'
if (-not (Test-Path -LiteralPath $buildScript)) {
    throw "No build-module.ps1 in $OutputFolder. AutoRest emits it; generate first."
}

Write-Step 3 'Building (compiles ~940 cmdlets and ~1250 models; several minutes)'
$log = Join-Path ([System.IO.Path]::GetTempPath()) "fogapi-build-$PID.log"

# Isolated process, and stdout captured: build-module.ps1 is chatty and the
# interesting part is whether the artifacts appeared.
& pwsh -NoProfile -NonInteractive -File $buildScript *>&1 |
    Tee-Object -FilePath $log | Out-Null

# The exit code is not the gate. Check what was produced.
$psd1 = Join-Path $OutputFolder 'FogApi.psd1'
$dll = Join-Path $OutputFolder 'bin/FogApi.private.dll'
$errors = @(Select-String -LiteralPath $log -Pattern 'error CS\d+').Count

if ($errors -gt 0 -or -not (Test-Path -LiteralPath $psd1)) {
    Write-Host ''
    Write-Host "BUILD FAILED -- $errors compile errors" -ForegroundColor Red
    Write-Host "  log: $log" -ForegroundColor Red
    if ($errors -gt 0) {
        Write-Host '  first few:' -ForegroundColor Red
        Select-String -LiteralPath $log -Pattern 'error CS\d+' |
            Select-Object -First 3 |
            ForEach-Object { Write-Host "    $($_.Line.Trim())" -ForegroundColor DarkRed }
    }
    Write-Host ''
    Write-Host '  IError errors on Get-Fog*Id / Get-Fog*Name mean a bare top-level' -ForegroundColor Yellow
    Write-Host '  array response has come back into the document. AutoRest cannot model' -ForegroundColor Yellow
    Write-Host '  one; the rows have to sit under `data`. See FOGProject/fogproject#1409.' -ForegroundColor Yellow
    throw 'Build failed.'
}

$dllSize = if (Test-Path -LiteralPath $dll) {
    '{0:N1} MB' -f ((Get-Item $dll).Length / 1MB)
} else { 'not found' }

Write-Host ''
Write-Host 'BUILD OK' -ForegroundColor Green
Write-Host "  compile errors : 0"
Write-Host "  assembly       : $dllSize"
Write-Host "  manifest       : $psd1"
Write-Host "  proxies        : $(@(Get-ChildItem (Join-Path $OutputFolder 'exports') -Filter *.ps1 -EA SilentlyContinue).Count)"

# --- 4. import ---------------------------------------------------------
if ($Import) {
    Write-Step 4 'Importing'
    # A separate process, so a failed import cannot poison this session and so
    # an already-loaded FogApi from the gallery does not shadow the build.
    & pwsh -NoProfile -NonInteractive -Command @"
Import-Module '$psd1' -ErrorAction Stop
`$c = Get-Command -Module FogApi
Write-Host ("  imported: " + `$c.Count + " commands") -ForegroundColor Green
`$bad = `$c.Name | Where-Object { `$_ -notmatch '-Fog' }
if (`$bad) { Write-Host ("  WITHOUT Fog prefix: " + (`$bad -join ', ')) -ForegroundColor Red }
else { Write-Host '  every command is Verb-Fog*' -ForegroundColor Green }
`$c | Group-Object Verb | Sort-Object Count -Descending |
    ForEach-Object { '    {0,-9} {1}' -f `$_.Name, `$_.Count }
"@
    Write-Host ''
    Write-Host 'To use it in your own session:' -ForegroundColor Cyan
    Write-Host "  Import-Module '$psd1'" -ForegroundColor Gray
    Write-Host ''
    Write-Host 'Note: the generated cmdlets have no credentials and no real base URL' -ForegroundColor Yellow
    Write-Host 'yet -- servers[0].url is a placeholder in an offline dump, and' -ForegroundColor Yellow
    Write-Host 'Module.cs builds a pipeline with no auth step. A live call needs the' -ForegroundColor Yellow
    Write-Host 'hand-written transport (custom/Invoke-FogApi.cs), which is not done.' -ForegroundColor Yellow
}
