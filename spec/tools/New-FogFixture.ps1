#Requires -Version 5.1
<#
.SYNOPSIS
Writes a Tests/Fixtures file per route class, from the class's own schema.

.DESCRIPTION
Get-FogMockResponse resolves an unmapped path by convention: `GET {class}`
looks for `{class}s.json`, `GET {class}/{id}` for `{class}.json`, and count,
names and ids are derived from the list fixture rather than given files of their
own. So a class opts into the whole mocked surface by having one file.

Fifty-two classes is fifty-two files, and hand-writing them would mean
transcribing field names the spec already knows -- which is the same mistake
this whole effort exists to stop. They are generated from the resolved spec, so
a field that changes upstream changes here on the next rebuild.

The row deliberately holds ONE object. Generated examples assert a
single-element array, because an emitter cannot know how many rows a server
would return; multi-row behaviour is asserted on the request sequence in
Get-FogPagedResult.Tests.ps1, which is where it belongs.

Values are shaped by each field's declared type, enum and length, so a fixture
never carries a value the server itself would reject.

Existing files are left alone unless -Force is given: several were hand-written
to support specific documented examples (hosts.json carries MeowMachine at id
42) and regenerating them would break those.

.PARAMETER Class
Only these classes. Omit for every class in the spec.

.PARAMETER Force
Overwrite fixtures that already exist.

.EXAMPLE
./spec/tools/New-FogFixture.ps1

Writes a fixture for every class that does not already have one.
#>
[CmdletBinding()]
param (
    [string[]]$Class,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$specRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$repoRoot = Split-Path -Parent $specRoot
$fixtureDir = Join-Path (Join-Path $repoRoot 'Tests') 'Fixtures'
$spec = Get-Content -LiteralPath (Join-Path $specRoot 'fog-api-spec.json') -Raw | ConvertFrom-Json

function Get-FieldSample {
    <#
    A value the server would accept for this field. Enum first, because an enum
    value is the only legal one; then the pattern's own example where the field
    carries one; then type.
    #>
    param($Field, [string]$TitleNoun)
    if ($Field.enum) { return @($Field.enum)[0] }
    switch ($Field.type) {
        'integer' { return 1 }
        'number'  { return 1 }
        'boolean' { return $true }
        default {
            if ($Field.name -eq 'name') {
                $sample = "Example$TitleNoun"
                # A pattern is a real constraint, not decoration: host names are
                # capped at 15 characters, so a long class name would produce a
                # fixture the server would refuse.
                if ($Field.maxLength -and $sample.Length -gt $Field.maxLength) {
                    $sample = $sample.Substring(0, $Field.maxLength)
                }
                return $sample
            }
            return ''
        }
    }
}

$classes = @($spec.schemas.PSObject.Properties.Name | Sort-Object)
if ($Class) { $classes = @($classes | Where-Object { $_ -in $Class }) }
if (-not $classes) { throw 'no classes matched' }

$written = 0
$skipped = 0
foreach ($className in $classes) {
    $schema = $spec.schemas.$className
    $titleNoun = (Get-Culture).TextInfo.ToTitleCase($className)

    $row = [ordered]@{}
    foreach ($field in $schema.fields) {
        $row[$field.name] = if ($field.name -eq 'id') { 1 } else { Get-FieldSample -Field $field -TitleNoun $titleNoun }
    }

    # The list fixture keys its rows by the class name, which is FOG 1.5's
    # envelope. Add-FogResultData normalises it, and the mock's row reader takes
    # whichever property holds a collection, so either spelling works.
    $listPath = Join-Path $fixtureDir "$($className)s.json"
    $onePath = Join-Path $fixtureDir "$className.json"

    # When a list fixture already exists -- several were hand-authored, carrying
    # values older tests depend on -- the single-object fixture is derived from
    # its first row rather than invented. Otherwise the two disagree, and a
    # generated example is asserted against whichever one the mock happens to
    # pick: the list route reads the plural file, a fetch by id the singular.
    $singleBody = $row
    if (Test-Path -LiteralPath $listPath) {
        try {
            $existing = Get-Content -LiteralPath $listPath -Raw | ConvertFrom-Json
            $rows = @($existing.PSObject.Properties |
                Where-Object { $_.Name -ne 'count' -and $_.Value -is [System.Collections.IEnumerable] -and $_.Value -isnot [string] } |
                Select-Object -First 1)
            if ($rows.Count -gt 0 -and @($rows[0].Value).Count -gt 0) {
                $singleBody = @($rows[0].Value)[0]
                # Only when the singular does not exist yet. Deriving over an
                # existing one overwrote a hand-authored fixture that carried
                # values another test depended on -- imaginglog held host 42 and
                # "Windows 10" for Get-LastImageTime, and regenerating it made
                # that test fail with no hint of why.
                if (-not (Test-Path -LiteralPath $onePath)) {
                    $json = $singleBody | ConvertTo-Json -Depth 5
                    Set-Content -LiteralPath $onePath -Value $json -Encoding utf8
                    $written++
                }
                $singleBody = $null
            }
        } catch { }
    }

    foreach ($pair in @(
        @{ Path = $listPath; Body = [ordered]@{ count = 1; "$($className)s" = @($row) } },
        @{ Path = $onePath;  Body = $singleBody }
    )) {
        if ($null -eq $pair.Body) { continue }
        if ((Test-Path -LiteralPath $pair.Path) -and -not $Force) {
            $skipped++
            continue
        }
        $json = $pair.Body | ConvertTo-Json -Depth 5
        Set-Content -LiteralPath $pair.Path -Value $json -Encoding utf8
        $written++
    }
}

Write-Host "wrote $written fixture(s), left $skipped existing file(s) alone"
