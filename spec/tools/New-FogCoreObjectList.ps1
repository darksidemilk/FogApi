#Requires -Version 5.1
<#
.SYNOPSIS
Writes FogApi/Private/Get-FogCoreObjectList.ps1 from the resolved spec.

.DESCRIPTION
Get-DynmicParam built the -coreObject ValidateSet from a class list typed into
the file. It had drifted: seven classes the 1.6 server serves were missing --
filedeletequeue, role, rolepermission, roleuserassociation,
roleusergroupassociation, usergroup, usergroupmember -- so every L1 call for
those was refused during parameter binding, and generated cmdlets for them could
not work at all.

The spec knows the real list, so the list is generated from it.

Two entries are kept that are NOT route classes:

  unisearch        Find-FogObject's sentinel for a universal search, not a class
  siteassociation  a name older callers may already pass

Entries CAN now leave the 1.6 list. That reverses the original rule here, which
was "removing a ValidateSet entry breaks callers and adding one never does", and
the reversal is deliberate: FogApi targets the latest 1.6, so a name the server
no longer routes should not tab-complete into a 404. imaginglog was the first,
retired upstream by ADR 0022 with taskLog.imageName replacing it. See
docs/plans/api-coverage-plan.md, "Locked decisions".

The two kept entries above are not an exception to that -- neither was ever a
route class, so neither can be retired by the server.

The 1.5 list stays hand-maintained. That line ships no schema manifest, so
nothing describes it, and inventing a generated list for it would be a guess
dressed as a fact.

.PARAMETER SpecFile
Path to the resolved spec. Defaults to spec/fog-api-spec.json.

.PARAMETER OutFile
Where to write. Defaults to FogApi/Private/Get-FogCoreObjectList.ps1.

.EXAMPLE
./spec/tools/New-FogCoreObjectList.ps1
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
if (-not $OutFile) {
    $OutFile = Join-Path (Join-Path (Join-Path $repoRoot 'FogApi') 'Private') 'Get-FogCoreObjectList.ps1'
}

$spec = Get-Content -LiteralPath $SpecFile -Raw | ConvertFrom-Json
$classes = @($spec.schemas.PSObject.Properties.Name)

# Never removed, for the reasons in the help above.
$keep = @('unisearch', 'siteassociation')
$all = @(($classes + $keep) | Sort-Object -Unique)

$lines = [System.Collections.Generic.List[string]]::new()
$chunk = [System.Collections.Generic.List[string]]::new()
foreach ($c in $all) {
    $chunk.Add("'$c'")
    if ($chunk.Count -eq 6) {
        $lines.Add('            ' + ($chunk -join ', ') + ',')
        $chunk.Clear()
    }
}
if ($chunk.Count -gt 0) { $lines.Add('            ' + ($chunk -join ', ')) }
$lines[$lines.Count - 1] = $lines[$lines.Count - 1].TrimEnd(',')

$content = @"
function Get-FogCoreObjectList {
<#
.SYNOPSIS
The -coreObject ValidateSet values for a given fog version.

.DESCRIPTION
GENERATED FILE. Do not edit. Rebuild with spec/tools/New-FogCoreObjectList.ps1.

The 1.6 list is every route class the server serves, taken from
spec/fog-api-spec.json, which is built from the server's own OpenAPI document.
It used to be typed into Get-DynmicParam and had drifted by seven classes --
role, rolepermission, roleuserassociation, roleusergroupassociation, usergroup,
usergroupmember and filedeletequeue -- which made every L1 call for those fail
during parameter binding rather than at the server.

Two entries are not route classes and are kept deliberately, because removing a
ValidateSet entry breaks callers while adding one never does:

  unisearch        Find-FogObject's sentinel for a universal search
  siteassociation  a spelling older callers may already pass

The 1.5 list is hand-maintained: that line ships no schema manifest, so there is
nothing to generate it from, and a generated one would be a guess.

.PARAMETER version
The fog version string, as Get-FogVersion reports it.

.EXAMPLE
Get-FogCoreObjectList -version '1.6.0'

Returns the 1.6 class names.
#>
    [CmdletBinding()]
    param (
        [string]`$version
    )

    process {
        if (`$version -like '1.6*') {
            return @(
$($lines -join "`n")
            )
        }
        return @(
            'clientupdater', 'dircleaner', 'greenfog', 'group', 'groupassociation',
            'history', 'hookevent', 'host', 'hostautologout', 'hostscreensetting',
            'image', 'imageassociation', 'imagepartitiontype', 'imagetype',
            'imaginglog', 'inventory', 'ipxe', 'keysequence', 'macaddressassociation',
            'module', 'moduleassociation', 'multicastsession',
            'multicastsessionassociation', 'nodefailure', 'notifyevent', 'os', 'oui',
            'plugin', 'powermanagement', 'printer', 'printerassociation',
            'pxemenuoptions', 'scheduledtask', 'service', 'setting', 'snapin',
            'snapinassociation', 'snapingroupassociation', 'snapinjob', 'snapintask',
            'storagegroup', 'storagenode', 'task', 'tasklog', 'taskstate', 'tasktype',
            'unisearch', 'user', 'usercleanup', 'usertracking', 'virus'
        )
    }

}
"@

Set-Content -LiteralPath $OutFile -Value $content -Encoding utf8
Write-Host "wrote $OutFile with $($all.Count) 1.6 class names"
