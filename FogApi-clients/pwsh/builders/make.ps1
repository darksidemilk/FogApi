<#
.SYNOPSIS
    Builds the PowerShell client, one stage at a time or all of them.

.DESCRIPTION
    The pwsh client's orchestrator. The root make.ps1 / make.sh dispatch here;
    run it directly when working on this client alone.

    Every stage is a function in buildFunctions.psm1 and is runnable on its
    own, so -Target exists to run exactly one when that is what you want:

      Document   produce the OpenAPI document (snapshot, checkout, or server)
      Generate   AutoRest -> src/
      Compile    build-module.ps1, checked by artifact rather than exit code
      Surface    record or check the public surface snapshot
      Merge      fold in src/custom/ (a real stage, nothing to do yet)
      Help       generate help from the compiled cmdlets
      Test       import the module and check its surface
      All        every stage above, in order

    What this does NOT build is the hand-written module. That is a different
    module with a different toolchain (PlatyPS, psm1 concatenation) and it
    stays callable on its own via ../invoke-modulebuild.ps1 until its helpers
    are ported into src/custom/.

.PARAMETER Target
    One stage, or All. Defaults to All.

.PARAMETER Web
    Generate from a fogproject checkout's packages/web instead of the
    committed snapshot. No server or database needed.

.PARAMETER Live
    Generate from a running FOG server's document, e.g.
    https://fog.example.com/fog. The only way to pick up that server's plugins,
    and the only way the client learns a real base URL -- servers[0].url is
    compiled in, and an offline dump emits a placeholder.

.PARAMETER CheckSurface
    In the Surface stage, compare instead of record, and fail on any change.
    This is the CI gate.

.EXAMPLE
    ./make.ps1
    Everything, from the committed snapshot.

.EXAMPLE
    ./make.ps1 -Live https://fog.example.com/fog
    Everything, against a real server's document.

.EXAMPLE
    ./make.ps1 -Target Compile
    Just recompile what is already generated.
#>
[CmdletBinding()]
param(
    [ValidateSet('Document', 'Generate', 'Compile', 'Surface', 'Merge', 'Help', 'Test', 'All')]
    [string]$Target = 'All',
    [string]$Web,
    [string]$Live,
    [switch]$CheckSurface
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'buildFunctions.psm1') -Force

$paths = Get-FogApiBuildPath
$step = 0
function Write-Stage($name) {
    $script:step++
    Write-Host ''
    Write-Host "[$script:step] $name" -ForegroundColor Cyan
}

$all = $Target -eq 'All'
$document = $null

if ($all -or $Target -eq 'Document') {
    Write-Stage 'Document'
    $document = Get-FogApiDocument -Web $Web -Live $Live
    Write-Host "  $document" -ForegroundColor DarkGray
}

if ($all -or $Target -eq 'Generate') {
    Write-Stage 'Generate'
    if (-not $document) { $document = Get-FogApiDocument -Web $Web -Live $Live }
    Invoke-FogApiGeneration -Document $document
}

if ($all -or $Target -eq 'Compile') {
    Write-Stage 'Compile'
    $built = Invoke-FogApiCompile
    Write-Host "  0 compile errors, assembly $($built.SizeMB) MB, $($built.Proxies) proxies" -ForegroundColor Green
}

if ($all -or $Target -eq 'Merge') {
    Write-Stage 'Merge custom code'
    Merge-FogApiCustomCode
}

if ($all -or $Target -eq 'Surface') {
    Write-Stage $(if ($CheckSurface) { 'Surface (check)' } else { 'Surface (record)' })
    Update-FogApiSurface -Check:$CheckSurface
}

if ($all -or $Target -eq 'Help') {
    Write-Stage 'Help'
    Build-FogApiHelp
}

if ($all -or $Target -eq 'Test') {
    Write-Stage 'Test'
    Test-FogApiModule
}

Write-Host ''
Write-Host 'done' -ForegroundColor Green
if (Test-Path -LiteralPath $paths.Manifest) {
    Write-Host "  Import-Module '$($paths.Manifest)'" -ForegroundColor Gray
    Write-Host ''
    Write-Host '  The generated cmdlets have no credential step yet, and unless the' -ForegroundColor Yellow
    Write-Host '  document came from -Live the base URL is a placeholder. Reaching a' -ForegroundColor Yellow
    Write-Host '  real server needs src/custom/Invoke-FogApi.cs, which is not written.' -ForegroundColor Yellow
}
