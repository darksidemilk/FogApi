<#
    Build stages for the PowerShell client.

    One function per stage, each runnable on its own. make.ps1 (and make.sh,
    which delegates to it) calls them in order. Nothing here assumes it is
    being called by the orchestrator.

    Paths are resolved from $PSScriptRoot, never the working directory. Several
    of the scripts these replace used `.\something`, which worked only when the
    caller happened to be standing in the right folder.
#>

$script:BuilderRoot = $PSScriptRoot
$script:ClientRoot = Split-Path $PSScriptRoot -Parent
$script:RepoRoot = Split-Path (Split-Path $script:ClientRoot -Parent) -Parent
$script:ScaffoldPath = Join-Path $script:ClientRoot 'src'
$script:SpecPath = Join-Path $script:RepoRoot 'spec'

function Get-FogApiBuildPath {
    <#
    .SYNOPSIS
        The paths every stage works from.
    .DESCRIPTION
        Exposed so a stage run by hand, or a test, can ask where things are
        rather than recomputing the same Split-Path chain and getting it
        subtly wrong.
    #>
    [CmdletBinding()]
    param()
    [pscustomobject]@{
        RepoRoot   = $script:RepoRoot
        ClientRoot = $script:ClientRoot
        Builders   = $script:BuilderRoot
        Scaffold   = $script:ScaffoldPath
        Spec       = $script:SpecPath
        Snapshot   = Join-Path $script:SpecPath 'openapi/fog-1.6.json'
        Generators = Join-Path $script:SpecPath 'generators'
        Manifest   = Join-Path $script:ScaffoldPath 'FogApi.psd1'
        Assembly   = Join-Path $script:ScaffoldPath 'bin/FogApi.private.dll'
        Custom     = Join-Path $script:ScaffoldPath 'custom'
        Output     = Join-Path $script:RepoRoot '_module_build/FogApi'
    }
}

function Test-FogApiPrerequisite {
    <#
    .SYNOPSIS
        Checks the tools a given stage needs, and says which stage needs them.
    .DESCRIPTION
        Checked up front rather than letting a stage fail three minutes in
        with a message about a missing binary.
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Document', 'Generate', 'Compile', 'All')]
        [string]$Stage = 'All'
    )

    $needed = @{
        Document = @{ php = 'dumping the OpenAPI document from a checkout' }
        Generate = @{ npx = 'running AutoRest' ; node = 'running AutoRest' }
        Compile  = @{ dotnet = 'compiling the generated C#' }
    }

    $stages = if ($Stage -eq 'All') { $needed.Keys } else { @($Stage) }
    $missing = @()

    foreach ($s in $stages) {
        foreach ($tool in $needed[$s].Keys) {
            if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
                $missing += "  $tool -- needed for $($needed[$s][$tool])"
            }
        }
    }

    if ($missing.Count -gt 0) {
        throw "Missing prerequisites:`n$($missing -join "`n")"
    }
    Write-Verbose "prerequisites for '$Stage' present"
}

function Get-FogApiDocument {
    <#
    .SYNOPSIS
        Produces the OpenAPI document a build generates from.
    .DESCRIPTION
        Three sources, in order of specificity:

        -Web        dump from a fogproject checkout. No server, no database.
        -Live       fetch from a running server. This is the only way plugin
                    classes appear, AND the only way the generated client
                    learns a real base URL: servers[0].url is compiled in at
                    989 call sites, and an offline dump has no request to read
                    a host from, so it emits a placeholder.
        neither     the committed snapshot.
    .PARAMETER Web
        Path to a fogproject checkout's packages/web.
    .PARAMETER Live
        Base URL of a running FOG server, e.g. https://fog.example.com/fog.
    #>
    [CmdletBinding()]
    param(
        [string]$Web,
        [string]$Live
    )

    $p = Get-FogApiBuildPath

    if ($Web -and $Live) {
        throw 'Pass -Web or -Live, not both.'
    }

    if ($Live) {
        $uri = ($Live.TrimEnd('/')) + '/system/openapi'
        $out = Join-Path ([System.IO.Path]::GetTempPath()) "fog-openapi-live-$PID.json"
        Write-Host "  fetching $uri" -ForegroundColor DarkGray
        # Both openapi routes are in the router's unauthenticated allowlist, so
        # discovery needs no tokens.
        Invoke-WebRequest -Uri $uri -OutFile $out -UseBasicParsing -ErrorAction Stop
        return $out
    }

    if ($Web) {
        Test-FogApiPrerequisite -Stage Document
        if (-not (Test-Path -LiteralPath (Join-Path $Web 'lib/fog'))) {
            throw "Not a packages/web directory (no lib/fog): $Web"
        }
        $out = Join-Path ([System.IO.Path]::GetTempPath()) "fog-openapi-$PID.json"
        & php (Join-Path $p.Spec 'tools/dump-openapi.php') --web $Web --out $out
        if ($LASTEXITCODE -ne 0) {
            throw "dump-openapi.php failed with exit code $LASTEXITCODE"
        }
        return $out
    }

    if (-not (Test-Path -LiteralPath $p.Snapshot)) {
        throw "No committed snapshot at $($p.Snapshot), and neither -Web nor -Live given."
    }
    Write-Host "  using committed snapshot" -ForegroundColor DarkGray
    return $p.Snapshot
}

function Invoke-FogApiGeneration {
    <#
    .SYNOPSIS
        Generates the client from a document with AutoRest.
    .DESCRIPTION
        Delegates to spec/generators/Invoke-FogApiGeneration.ps1, which owns
        the pinned generator versions and the two gates (operationIds carry
        the verb underscore; zero inference warnings). The config lives with
        the spec because that is where every client's generator config lives.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Document,
        [string]$OutputFolder
    )
    Test-FogApiPrerequisite -Stage Generate
    $p = Get-FogApiBuildPath
    if (-not $OutputFolder) { $OutputFolder = $p.Scaffold }

    & (Join-Path $p.Generators 'Invoke-FogApiGeneration.ps1') `
        -InputFile $Document -OutputFolder $OutputFolder | Out-Host
}

function Invoke-FogApiCompile {
    <#
    .SYNOPSIS
        Compiles the generated C# and exports the PowerShell proxies.
    .DESCRIPTION
        Runs AutoRest's own build-module.ps1, then checks the artifacts.

        **build-module.ps1 exits 0 when compilation fails** -- it calls
        Write-Error and returns success. The first attempt ever made to build
        this module failed with 333 compile errors and reported success. So
        the gate here is the manifest existing and the log being free of
        `error CS`, never the exit code.
    #>
    [CmdletBinding()]
    param(
        [string]$Scaffold
    )
    Test-FogApiPrerequisite -Stage Compile
    $p = Get-FogApiBuildPath
    if (-not $Scaffold) { $Scaffold = $p.Scaffold }

    $buildScript = Join-Path $Scaffold 'build-module.ps1'
    if (-not (Test-Path -LiteralPath $buildScript)) {
        throw "No build-module.ps1 in $Scaffold. AutoRest emits it; run the generate stage first."
    }

    $log = Join-Path ([System.IO.Path]::GetTempPath()) "fogapi-compile-$PID.log"
    & pwsh -NoProfile -NonInteractive -File $buildScript *>&1 |
        Tee-Object -FilePath $log | Out-Null

    $errors = @(Select-String -LiteralPath $log -Pattern 'error CS\d+').Count
    $manifest = Join-Path $Scaffold 'FogApi.psd1'

    if ($errors -gt 0 -or -not (Test-Path -LiteralPath $manifest)) {
        Select-String -LiteralPath $log -Pattern 'error CS\d+' |
            Select-Object -First 3 |
            ForEach-Object { Write-Host "    $($_.Line.Trim())" -ForegroundColor DarkRed }
        Write-Host ''
        Write-Host '  IError errors on Get-Fog*Id / Get-Fog*Name mean a bare top-level' -ForegroundColor Yellow
        Write-Host '  array response is back in the document. AutoRest cannot model one;' -ForegroundColor Yellow
        Write-Host '  the rows must sit under `data`. See FOGProject/fogproject#1409.' -ForegroundColor Yellow
        throw "Compilation failed: $errors errors. Log: $log"
    }

    $dll = Join-Path $Scaffold 'bin/FogApi.private.dll'
    [pscustomobject]@{
        Manifest = $manifest
        Assembly = if (Test-Path -LiteralPath $dll) { $dll } else { $null }
        SizeMB   = if (Test-Path -LiteralPath $dll) {
            [math]::Round((Get-Item $dll).Length / 1MB, 1)
        } else { 0 }
        Proxies  = @(Get-ChildItem (Join-Path $Scaffold 'exports') -Filter *.ps1 -EA SilentlyContinue).Count
        Log      = $log
    }
}

function Update-FogApiSurface {
    <#
    .SYNOPSIS
        Records or checks the public cmdlet surface.
    .DESCRIPTION
        The generated tree is not committed, so this snapshot is the only place
        a rename or a dropped parameter becomes visible in review. -Check is
        the CI gate.
    #>
    [CmdletBinding()]
    param(
        [switch]$Check
    )
    $p = Get-FogApiBuildPath
    $script = Join-Path $p.Generators 'Update-FogApiSurface.ps1'

    # A child process, so the exit code is real. Update-FogApiSurface.ps1
    # signals drift with `exit 1`, and $LASTEXITCODE after calling a .ps1
    # in-process is unreliable -- PowerShell sets it for native commands, so
    # it is either stale or $null, and `$null -ne 0` is true.
    $childArgs = @('-NoProfile', '-NonInteractive', '-File', $script,
        '-GeneratedRoot', $p.Scaffold)
    if ($Check) { $childArgs += '-Check' }

    & pwsh @childArgs | Out-Host
    if ($Check -and $LASTEXITCODE -ne 0) {
        throw 'The generated surface no longer matches the committed snapshot. Run the Surface stage without -CheckSurface to accept it, and commit the change alongside whatever caused it.'
    }
}

function Merge-FogApiCustomCode {
    <#
    .SYNOPSIS
        Folds hand-written code into the generated module.
    .DESCRIPTION
        A real stage with nothing to do yet, deliberately.

        src/custom/ is the one scaffold directory AutoRest intends to be
        hand-edited, and it is where Invoke-FogApi.cs and the ~20 workflow
        helpers that survive triage will live. build-module.ps1 already merges
        custom/ into exports/ on its own, so once the port lands this stage may
        need to do nothing more than assert the result.

        What it will NOT do silently is skip. Two things have to be settled
        before hand-written source can live under src/, and both are easy to
        forget:

          - .gitignore excludes all of FogApi-clients/pwsh/src/, so committed
            hand-written code would be invisible to git
          - the generate stage passes --clear-output-folder, which empties the
            output folder before generating

        So if custom/ has content, this fails until someone has dealt with
        both. Failing loudly beats generating over the top of source that
        exists nowhere else.
    #>
    [CmdletBinding()]
    param()

    $p = Get-FogApiBuildPath
    if (-not (Test-Path -LiteralPath $p.Custom)) {
        Write-Host '  nothing to merge (no src/custom/ yet)' -ForegroundColor DarkGray
        return
    }

    # AutoRest emits a README and an empty .custom.psm1 into custom/ itself;
    # those are not ours and do not count as content.
    $ours = @(Get-ChildItem -LiteralPath $p.Custom -Recurse -File -EA SilentlyContinue |
        Where-Object { $_.Name -notmatch '^(README\.md|FogApi\.custom\.psm1)$' })

    if ($ours.Count -eq 0) {
        Write-Host '  nothing to merge (src/custom/ holds only AutoRest placeholders)' -ForegroundColor DarkGray
        return
    }

    throw @"
src/custom/ contains $($ours.Count) hand-written file(s), and this stage does
not yet know how to protect them:

$($ours.Name -join "`n")

Before hand-written source lives under src/, settle both of these:

  1. .gitignore excludes FogApi-clients/pwsh/src/ entirely, so this code is
     not being committed. Narrow it:
       FogApi-clients/pwsh/src/*
       !FogApi-clients/pwsh/src/custom/

  2. The generate stage passes --clear-output-folder. Confirm it spares
     custom/ before trusting it with source that exists nowhere else.

Then teach this stage what 'merged' means and remove this throw.
"@
}

function Build-FogApiHelp {
    <#
    .SYNOPSIS
        Generates help for the built module.
    .DESCRIPTION
        Uses AutoRest's own generate-help.ps1, which reads the compiled
        cmdlets. The hand-written module's PlatyPS path is a different thing
        for a different module and is not called from here -- see
        invoke-modulebuild.ps1, which stays callable on its own.
    #>
    [CmdletBinding()]
    param()

    $p = Get-FogApiBuildPath
    $script = Join-Path $p.Scaffold 'generate-help.ps1'
    if (-not (Test-Path -LiteralPath $script)) {
        Write-Warning "No generate-help.ps1 in $($p.Scaffold); skipping help."
        return
    }
    & pwsh -NoProfile -NonInteractive -File $script *>&1 | Out-Host
}

function Test-FogApiModule {
    <#
    .SYNOPSIS
        Imports the built module and reports its surface.
    .DESCRIPTION
        In a separate process, so a failed import cannot poison the calling
        session and so an already-loaded FogApi from the gallery cannot shadow
        the build.
    #>
    [CmdletBinding()]
    param()

    $p = Get-FogApiBuildPath
    if (-not (Test-Path -LiteralPath $p.Manifest)) {
        throw "No built module at $($p.Manifest). Run the compile stage first."
    }

    & pwsh -NoProfile -NonInteractive -Command @"
Import-Module '$($p.Manifest)' -ErrorAction Stop
`$c = Get-Command -Module FogApi
Write-Host ("  imported: " + `$c.Count + " commands") -ForegroundColor Green
`$bad = `$c.Name | Where-Object { `$_ -notmatch '-Fog' }
if (`$bad) {
    Write-Host ("  WITHOUT the Fog prefix: " + (`$bad -join ', ')) -ForegroundColor Red
    exit 1
}
Write-Host '  every command is Verb-Fog*' -ForegroundColor Green
"@
    if ($LASTEXITCODE -ne 0) { throw 'Imported module failed its surface check.' }
}

Export-ModuleMember -Function @(
    'Get-FogApiBuildPath'
    'Test-FogApiPrerequisite'
    'Get-FogApiDocument'
    'Invoke-FogApiGeneration'
    'Invoke-FogApiCompile'
    'Update-FogApiSurface'
    'Merge-FogApiCustomCode'
    'Build-FogApiHelp'
    'Test-FogApiModule'
)
