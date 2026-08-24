<#
.SYNOPSIS
Rewrites the SOURCE manifest's FunctionsToExport and AliasesToExport from what
FogApi/Public actually contains.

.DESCRIPTION
invoke-modulebuild.ps1 updates only the _module_build copy of FogApi.psd1, never
the source, so the source lists drift the moment a function or alias is added.
That drift is not theoretical: Get-PendingMacsForHost was declared in code and
missing from AliasesToExport, and six documented examples failed with
CommandNotFoundException until someone noticed.

It matters more now than it did. Generated cmdlets arrive dozens at a time, and
hand-maintaining two alphabetised lists at that rate is a guarantee of drift.

Function names come from the file names in Public. Alias names come from the
PowerShell parser, so an alias is found wherever it is legally declared.

BuildHelpers' Get-AliasesToExport is not reused, for two reasons: it reads a
built psm1 rather than the source tree, so it cannot run before a build, and it
finds an alias by indexing the line immediately after the CmdletBinding
attribute. That second rule is narrower than the language, so it silently drops
an alias declared anywhere else. This script warns when it finds one the build
would miss, which turns a silent drop into a message.

.PARAMETER ModuleRoot
The module directory. Defaults to ./FogApi.

.PARAMETER Check
Report drift and exit non-zero without writing. This is the CI shape.

.EXAMPLE
./update-sourcemanifest.ps1

Rewrites both lists in FogApi/FogApi.psd1.

.EXAMPLE
./update-sourcemanifest.ps1 -Check

Fails if the manifest does not match the files on disk.
#>
[CmdletBinding()]
param (
    [string]$ModuleRoot,
    [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSCommandPath
if (-not $ModuleRoot) { $ModuleRoot = Join-Path $repoRoot 'FogApi' }

$manifestPath = Join-Path $ModuleRoot 'FogApi.psd1'
$publicDir = Join-Path $ModuleRoot 'Public'

$functions = @(Get-ChildItem -LiteralPath $publicDir -Filter '*.ps1' | Sort-Object BaseName | ForEach-Object { $_.BaseName })

$aliasList = [System.Collections.Generic.List[string]]::new()
foreach ($file in (Get-ChildItem -LiteralPath $publicDir -Filter '*.ps1' | Sort-Object BaseName)) {
    $tokens = $null; $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        throw "$($file.Name) does not parse: $($parseErrors[0].Message)"
    }
    $attributes = $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.AttributeAst] -and
            $node.TypeName.Name -in @('Alias', 'System.Management.Automation.AliasAttribute') },
        $true)
    foreach ($attr in $attributes) {
        # Parameter aliases are declared the same way and are not module
        # exports, so only attributes attached to the function itself count.
        $parent = $attr.Parent
        if ($parent -isnot [System.Management.Automation.Language.ParamBlockAst]) { continue }
        foreach ($arg in $attr.PositionalArguments) {
            if ($arg -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                $aliasList.Add($arg.Value)
            }
        }
        # The build finds an alias only on the line straight after
        # CmdletBinding. Anything further down is exported by this script and
        # dropped by the build, which is worth saying out loud.
        $cmdletBinding = @($parent.Attributes | Where-Object { $_.TypeName.Name -eq 'CmdletBinding' })[0]
        $offset = if ($cmdletBinding) { $attr.Extent.StartLineNumber - $cmdletBinding.Extent.StartLineNumber } else { 0 }
        if ($cmdletBinding -and $offset -ne 1) {
            $where = if ($offset -lt 0) {
                "$([math]::Abs($offset)) line(s) BEFORE CmdletBinding"
            } else {
                "$offset line(s) after CmdletBinding"
            }
            Write-Warning ("$($file.Name): the Alias attribute is $where. " +
                'invoke-modulebuild.ps1 reads only the line immediately after CmdletBinding, ' +
                'so the built module will not export this alias. Move it to the line right after CmdletBinding.')
        }
    }
}
# --- the compiled half ------------------------------------------------------
#
# A cmdlet's name and its aliases live in compiled metadata, so the AST walk
# above cannot see either. It does not fail loudly when that happens: it just
# returns a SHORTER list, the manifest is rewritten with it, and the module
# ships missing commands. Same failure shape as CmdletsToExport = @(). Every
# export list in this build degrades to a short list rather than to an error,
# and the gallery publishes a short list without complaint -- hence the floors
# at the end of this block.
#
# Reflected out of the built assembly rather than read from the spec, so the
# manifest describes the dll that is actually in bin/ and the two cannot drift.
#
# Loading an assembly locks it on windows and the caller may need to copy that
# same file afterwards, so this runs in a child pwsh.
$dllPath = Join-Path $ModuleRoot 'bin' 'FogApi.Core.dll'
$cmdlets = @()
$cmdletAliases = @()
if (Test-Path -LiteralPath $dllPath) {
    $reflect = {
        param($Dll)
        $asm = [System.Reflection.Assembly]::LoadFrom($Dll)
        $names = @(); $aka = @()
        foreach ($type in $asm.GetTypes()) {
            $attr = @($type.GetCustomAttributes([System.Management.Automation.CmdletAttribute], $false))
            if ($attr.Count -eq 0) { continue }
            $names += ('{0}-{1}' -f $attr[0].VerbName, $attr[0].NounName)
            foreach ($a in $type.GetCustomAttributes([System.Management.Automation.AliasAttribute], $false)) {
                $aka += $a.AliasNames
            }
        }
        [pscustomobject]@{ Cmdlets = $names; Aliases = $aka } | ConvertTo-Json -Compress
    }
    $json = & (Get-Process -Id $PID).Path -NoProfile -NonInteractive -Command $reflect -args $dllPath
    $reflected = $json | ConvertFrom-Json
    $cmdlets = @($reflected.Cmdlets | Sort-Object -Unique)
    $cmdletAliases = @($reflected.Aliases | Where-Object { $_ } | Sort-Object -Unique)
} else {
    # Refuse rather than carry on. Running without the assembly means every
    # cmdlet looks like it was deleted, and a manifest rewritten on that belief
    # ships a module with none of them. The whole point of this script is to
    # stop an export list silently getting shorter; doing it itself would be
    # the worst version of that.
    $declaredCmdlets = @((Import-PowerShellDataFile -LiteralPath $manifestPath).CmdletsToExport)
    if ($declaredCmdlets.Count -gt 0) {
        throw @"
No compiled assembly at $dllPath, but the manifest already exports $($declaredCmdlets.Count) cmdlet(s).

Continuing would rewrite the manifest as though every one of them had been
deleted. Run ./build-dotnet.ps1 first.
"@
    }
    Write-Warning "no compiled assembly at $dllPath and none exported; CmdletsToExport left alone."
}

$aliases = @(@($aliasList) + $cmdletAliases | Where-Object { $_ } | Sort-Object -Unique)

$manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
$currentFunctions = @($manifest.FunctionsToExport | Sort-Object)
$currentAliases = @($manifest.AliasesToExport | Sort-Object)
$currentCmdlets = @($manifest.CmdletsToExport | Sort-Object)

$fnMissing = @($functions | Where-Object { $_ -notin $currentFunctions })
$fnStale   = @($currentFunctions | Where-Object { $_ -notin $functions })
$alMissing = @($aliases | Where-Object { $_ -notin $currentAliases })
$alStale   = @($currentAliases | Where-Object { $_ -notin $aliases })
$cmMissing = @($cmdlets | Where-Object { $_ -notin $currentCmdlets })
$cmStale   = @($currentCmdlets | Where-Object { $_ -notin $cmdlets })

$drift = $fnMissing.Count + $fnStale.Count + $alMissing.Count + $alStale.Count + $cmMissing.Count + $cmStale.Count
if ($drift -eq 0) {
    Write-Host "manifest is in sync - $($functions.Count) functions, $($cmdlets.Count) cmdlets, $($aliases.Count) aliases"
    return
}

foreach ($n in $fnMissing) { Write-Host "  function declared but not exported: $n" -ForegroundColor Yellow }
foreach ($n in $fnStale)   { Write-Host "  exported but no such file:          $n" -ForegroundColor Yellow }
foreach ($n in $alMissing) { Write-Host "  alias declared but not exported:    $n" -ForegroundColor Yellow }
foreach ($n in $alStale)   { Write-Host "  alias exported but not declared:    $n" -ForegroundColor Yellow }
foreach ($n in $cmMissing) { Write-Host "  cmdlet compiled but not exported:   $n" -ForegroundColor Yellow }
foreach ($n in $cmStale)   { Write-Host "  cmdlet exported but not compiled:   $n" -ForegroundColor Yellow }

if ($Check) {
    throw "$drift manifest drift item(s). Run ./update-sourcemanifest.ps1 to fix."
}

function Format-ExportList {
    <#
    Written by hand rather than via Update-ModuleManifest, which rewrites the
    whole file and drops the comments the manifest carries.
    #>
    param([string]$Key, [string[]]$Names)
    $quoted = @($Names | ForEach-Object { "'$_'" })
    $lines = [System.Collections.Generic.List[string]]::new()
    $current = "$Key = "
    $indent = ' ' * 15
    foreach ($q in $quoted) {
        $candidate = if ($current.TrimEnd() -match '=$') { $current + $q } else { $current + ', ' + $q }
        if ($candidate.Length -gt 78 -and $current.TrimEnd() -notmatch '=$') {
            $lines.Add($current + ', ')
            $current = $indent + $q
        } else {
            $current = $candidate
        }
    }
    $lines.Add($current)
    $lines -join [Environment]::NewLine
}

$content = Get-Content -LiteralPath $manifestPath -Raw
$rewrite = @(
    @{ Key = 'FunctionsToExport'; Names = $functions },
    @{ Key = 'AliasesToExport';   Names = $aliases }
)
# Only when there is an assembly to reflect. Rewriting this from an empty list
# because the dll happens not to be built is exactly the silent-shortening this
# script exists to catch.
if ($cmdlets.Count -gt 0) { $rewrite += @{ Key = 'CmdletsToExport'; Names = $cmdlets } }

foreach ($pair in $rewrite) {
    # The value runs from the key to the last quoted name before the next
    # top-level key or comment, so it is matched as "everything up to a newline
    # that is not a continuation".
    $pattern = "(?ms)^$($pair.Key)\s*=.*?'(?=\s*\r?\n(?!\s{2,}'))"
    # CmdletsToExport starts life as @(), which has no quoted name to anchor on.
    $emptyPattern = "(?m)^$($pair.Key)\s*=\s*@\(\)\s*$"
    $replacement = Format-ExportList -Key $pair.Key -Names $pair.Names

    # The empty form is tested FIRST, and that ordering is load-bearing. The
    # quoted pattern is lazy and multiline, so against `CmdletsToExport = @()`
    # it does not fail to match -- it runs forward hunting for a quote, finds
    # the first one that satisfies the lookahead somewhere inside the NEXT key,
    # and rewrites both. That is how AliasesToExport disappeared from the
    # manifest entirely: 75 aliases replaced by three cmdlet names, no error,
    # and the key simply gone. Same silent-shortening this script exists to
    # catch, committed by the script itself.
    if ($content -match $emptyPattern) {
        $content = [regex]::Replace($content, $emptyPattern, { $replacement }, 1)
    } elseif ($content -match $pattern) {
        $content = [regex]::Replace($content, $pattern, { $replacement }, 1)
    } else {
        throw "could not locate $($pair.Key) in $manifestPath"
    }
}
Set-Content -LiteralPath $manifestPath -Value $content -Encoding utf8 -NoNewline

# Floors, not exact counts: adding a command must not fail this, losing most of
# them must. Every list here degrades to a shorter one rather than to an error,
# and PSGallery publishes a short list without complaint.
if ($functions.Count -lt 50) { throw "only $($functions.Count) functions found in Public/; expected ~200. Refusing to write a manifest that would ship a module missing most of its commands." }
if ($aliases.Count -lt 50)   { throw "only $($aliases.Count) aliases found; expected ~75. See the note above." }

Write-Host "updated ${manifestPath}: $($functions.Count) functions, $($cmdlets.Count) cmdlets, $($aliases.Count) aliases"
