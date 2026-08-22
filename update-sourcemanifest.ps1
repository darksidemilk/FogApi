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
$aliases = @($aliasList | Sort-Object -Unique)

$manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
$currentFunctions = @($manifest.FunctionsToExport | Sort-Object)
$currentAliases = @($manifest.AliasesToExport | Sort-Object)

$fnMissing = @($functions | Where-Object { $_ -notin $currentFunctions })
$fnStale   = @($currentFunctions | Where-Object { $_ -notin $functions })
$alMissing = @($aliases | Where-Object { $_ -notin $currentAliases })
$alStale   = @($currentAliases | Where-Object { $_ -notin $aliases })

$drift = $fnMissing.Count + $fnStale.Count + $alMissing.Count + $alStale.Count
if ($drift -eq 0) {
    Write-Host "manifest is in sync - $($functions.Count) functions, $($aliases.Count) aliases"
    return
}

foreach ($n in $fnMissing) { Write-Host "  function declared but not exported: $n" -ForegroundColor Yellow }
foreach ($n in $fnStale)   { Write-Host "  exported but no such file:          $n" -ForegroundColor Yellow }
foreach ($n in $alMissing) { Write-Host "  alias declared but not exported:    $n" -ForegroundColor Yellow }
foreach ($n in $alStale)   { Write-Host "  alias exported but not declared:    $n" -ForegroundColor Yellow }

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
foreach ($pair in @(
    @{ Key = 'FunctionsToExport'; Names = $functions },
    @{ Key = 'AliasesToExport';   Names = $aliases }
)) {
    # The value runs from the key to the last quoted name before the next
    # top-level key or comment, so it is matched as "everything up to a newline
    # that is not a continuation".
    $pattern = "(?ms)^$($pair.Key)\s*=.*?'(?=\s*\r?\n(?!\s{2,}'))"
    $replacement = Format-ExportList -Key $pair.Key -Names $pair.Names
    if ($content -notmatch $pattern) { throw "could not locate $($pair.Key) in $manifestPath" }
    $content = [regex]::Replace($content, $pattern, { $replacement }, 1)
}
Set-Content -LiteralPath $manifestPath -Value $content -Encoding utf8 -NoNewline

Write-Host "updated ${manifestPath}: $($functions.Count) functions, $($aliases.Count) aliases"
