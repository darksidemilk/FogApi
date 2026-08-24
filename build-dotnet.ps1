<#
.SYNOPSIS
Compiles FogApi's C# core into FogApi/bin.

.DESCRIPTION
The only place `dotnet` is invoked. Both build scripts call this rather than
shelling out themselves, so there is one definition of what "build the compiled
half" means.

The output lands in FogApi/bin rather than an artifacts folder because the
module has to be importable from the source tree: build.ps1 imports it to
generate docs, CI's settings-bootstrap check imports it, and every
Tests/*.Tests.ps1 BeforeAll imports it. A dll anywhere else is a dll the
manifest's RequiredAssemblies cannot find.

FogApi/bin is gitignored. The generated .cs under src/ is what gets committed,
the same rule the generated .ps1 files follow: the source is reviewable as a
diff, the compilation of it is not.

.PARAMETER Configuration
Debug or Release. Release by default; ./dev.ps1 uses Debug for a faster loop.

.PARAMETER OutDir
Where the assembly goes. Defaults to FogApi/bin.

.PARAMETER Version
Stamps AssemblyVersion, FileVersion and InformationalVersion. build.ps1 passes
the module version it just computed, so the assembly and the manifest cannot
disagree about what release they belong to.

.EXAMPLE
./build-dotnet.ps1

.EXAMPLE
./build-dotnet.ps1 -Configuration Debug
#>
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [string]$OutDir,

    [string]$Version
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$project = Join-Path $PSScriptRoot 'src' 'FogApi.Cmdlets' 'FogApi.Cmdlets.csproj'
if (-not $OutDir) { $OutDir = Join-Path $PSScriptRoot 'FogApi' 'bin' }

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw @"
FogApi's compiled core needs the .NET 8 SDK, and no dotnet was found on PATH.

  winget install Microsoft.DotNet.SDK.8      (windows)
  https://dot.net/download                   (everywhere else)

Installing FogApi from the PowerShell Gallery needs none of this -- the SDK is
only required to build from source.
"@
}

# PowerShell cannot unload an assembly. If any session in this process tree has
# imported the module, the dll is memory mapped and the publish below fails with
# an MSBuild error that says nothing about why. Say why.
$dll = Join-Path $OutDir 'FogApi.Core.dll'
if (Test-Path -LiteralPath $dll) {
    try {
        [System.IO.File]::Open($dll, 'Open', 'ReadWrite', 'None').Dispose()
    } catch {
        throw @"
$dll is locked, which means a PowerShell session has FogApi imported.

PowerShell has no way to unload an assembly, so the file stays locked until that
process exits. Close it and run this again, or use ./dev.ps1, which does every
import in a child pwsh for exactly this reason.
"@
    }
}

$arguments = @(
    'publish', $project
    '-c', $Configuration
    '-f', 'net8.0'
    '-o', $OutDir
    '--nologo'
)
if ($Version) {
    $arguments += @("-p:Version=$Version", "-p:FileVersion=$Version", "-p:InformationalVersion=$Version")
}

Write-Verbose "dotnet $($arguments -join ' ')"
& dotnet @arguments
if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed with exit code $LASTEXITCODE" }

# Belt and braces on the dependency closure. PrivateAssets="all" in the csproj
# should already mean the only outputs are these, but a transitive package added
# later would quietly start shipping its own dependency tree into a PSGallery
# package, and nobody would notice until an assembly conflict in someone else's
# session.
$keep = @('FogApi.Core.dll', 'FogApi.Core.pdb', 'FogApi.Core.deps.json', 'FogApi.Core.xml')
$unexpected = @(Get-ChildItem -LiteralPath $OutDir -File | Where-Object { $_.Name -notin $keep })
if ($unexpected) {
    Write-Warning "removing unexpected publish output: $($unexpected.Name -join ', ')"
    $unexpected | Remove-Item -Force
}
Get-ChildItem -LiteralPath $OutDir -Directory | Remove-Item -Recurse -Force

Write-Host ("built {0} ({1})" -f $dll, $Configuration)
Get-ChildItem -LiteralPath $OutDir -File | ForEach-Object { Write-Host ("  {0,-24} {1,8:N0} bytes" -f $_.Name, $_.Length) }
