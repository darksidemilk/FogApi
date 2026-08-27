<#
.SYNOPSIS
    Builds a FogApi client from the shared spec.

.DESCRIPTION
    The one entry point. Dispatches to a client's own orchestrator under
    FogApi-clients/<client>/builders/make.ps1 -- so this script never has to
    know how a client is built, only that it can be.

    make.sh is the same CLI for Linux and macOS. It locates pwsh and calls
    this, rather than reimplementing the stages: AutoRest's build-module.ps1
    hard-requires PowerShell Core, so there is nothing to gain from a second
    implementation that would drift.

    Modularity is deliberate. Each client's stages are separate functions,
    each runnable alone, and -Target passes straight through -- so
    `./make.ps1 -Target Compile` recompiles without regenerating. Running the
    whole orchestration is the default, not the only option.

.PARAMETER Client
    Which client to build. 'all' builds every client that has a builders
    directory. Defaults to pwsh.

.PARAMETER Target
    A single stage, or All. Stage names are the client's own; run
    `./make.ps1 -Client pwsh -Help` to see them.

.PARAMETER Web
    Generate from a fogproject checkout's packages/web rather than the
    committed snapshot. Needs php; no server or database.

.PARAMETER Live
    Generate from a running FOG server's document, e.g.
    https://fog.example.com/fog. The only way to pick up that server's plugin
    classes, and the only way a generated client learns a real base URL.

.PARAMETER CheckSurface
    Compare the public surface against the committed snapshot and fail on any
    change, instead of recording it. The CI gate.

.PARAMETER Help
    Show the selected client's own help and exit.

.EXAMPLE
    ./make.ps1
    Builds the PowerShell client from the committed snapshot.

.EXAMPLE
    ./make.ps1 -Live https://fog.example.com/fog
    Builds against a real server's document, plugins included.

.EXAMPLE
    ./make.ps1 -Target Compile
    Recompiles what is already generated.

.EXAMPLE
    ./make.ps1 -Client all
    Builds every client that has builders.
#>
[CmdletBinding()]
param(
    [string]$Client = 'pwsh',
    [string]$Target = 'All',
    [string]$Web,
    [string]$Live,
    [switch]$CheckSurface,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

$clientsRoot = Join-Path $PSScriptRoot 'FogApi-clients'
if (-not (Test-Path -LiteralPath $clientsRoot)) {
    throw "No FogApi-clients directory beside this script."
}

# A client is buildable when it has builders/make.ps1. python/ exists as
# scaffolding and deliberately has no orchestrator yet, so it is listed as
# planned rather than silently attempted.
$discovered = Get-ChildItem -LiteralPath $clientsRoot -Directory | ForEach-Object {
    [pscustomobject]@{
        Name      = $_.Name
        Make      = Join-Path $_.FullName 'builders/make.ps1'
        Buildable = Test-Path -LiteralPath (Join-Path $_.FullName 'builders/make.ps1')
    }
}

if ($Client -eq 'all') {
    $targets = @($discovered | Where-Object Buildable)
    if ($targets.Count -eq 0) { throw 'No client has a builders/make.ps1.' }
} else {
    $targets = @($discovered | Where-Object Name -eq $Client)
    if ($targets.Count -eq 0) {
        throw "Unknown client '$Client'. Available: $(($discovered.Name) -join ', ')"
    }
    if (-not $targets[0].Buildable) {
        throw "Client '$Client' has no builders/make.ps1 yet. It is scaffolding; see FogApi-clients/$Client/README.md."
    }
}

$skipped = @($discovered | Where-Object { -not $_.Buildable })
if ($Client -eq 'all' -and $skipped.Count -gt 0) {
    Write-Host "not yet buildable, skipping: $(($skipped.Name) -join ', ')" -ForegroundColor DarkGray
}

foreach ($t in $targets) {
    Write-Host ''
    Write-Host "=== $($t.Name) ===" -ForegroundColor Magenta

    if ($Help) {
        Get-Help $t.Make -Detailed
        continue
    }

    $forward = @{ Target = $Target }
    if ($Web) { $forward['Web'] = $Web }
    if ($Live) { $forward['Live'] = $Live }
    if ($CheckSurface) { $forward['CheckSurface'] = $true }

    # try/catch, not $LASTEXITCODE. PowerShell only sets $LASTEXITCODE for
    # native commands, so after calling a .ps1 it is whatever a previous
    # native call left there -- or $null on a clean run, and `$null -ne 0` is
    # true, which failed every successful build.
    #
    # The client orchestrator sets $ErrorActionPreference = 'Stop', so a real
    # failure arrives here as an exception.
    try {
        & $t.Make @forward
    } catch {
        throw "$($t.Name) build failed: $($_.Exception.Message)"
    }
}
