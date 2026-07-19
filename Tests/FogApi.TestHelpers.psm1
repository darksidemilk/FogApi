#
# Shared helpers for the FogApi Pester suite.
# Not a *.Tests.ps1 file, so Pester does not auto-discover it - it is
# explicitly imported by the test files and by Invoke-FogApiTests.ps1.
#
# The convention these helpers rely on: a function's comment-based help can
# include, inside an .EXAMPLE block's remarks (after the normal prose
# description), a line that is exactly "Expected output:" followed by a
# JSON payload. Get-FogExampleCase turns every such annotated example into
# a Pester test case; Get-FogMockResponse fakes the one network seam
# (Invoke-FogApi) all of those examples ultimately call through.
#

$script:FixturesPath = Join-Path $PSScriptRoot 'Fixtures'

function Get-FogExampleCase {
    <#
    .SYNOPSIS
    Builds Pester test cases from Expected output: annotated .EXAMPLE blocks.

    .DESCRIPTION
    For each given function name, reads its comment-based help via Get-Help
    (the native help engine - not the generated markdown, so PlatyPS's
    single-line-example-code limitation does not apply here) and emits one
    case per .EXAMPLE whose remarks contain an "Expected output:" marker.
    Throws immediately if a marker's payload is not valid JSON, so a typo in
    the docs fails fast at test discovery instead of silently being skipped.

    .PARAMETER FunctionName
    One or more public function names to inspect for annotated examples.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$FunctionName
    )

    $cases = New-Object System.Collections.Generic.List[object]

    foreach ($name in $FunctionName) {
        $help = Get-Help -Name $name -Full
        $examples = $help.Examples.Example
        if ($null -eq $examples) {
            continue
        }

        foreach ($example in $examples) {
            $remarksText = ($example.remarks | ForEach-Object { $_.Text }) -join "`n"
            $match = [regex]::Match($remarksText, '(?ms)^\s*Expected output:\s*\r?\n(?<json>.+)\z')
            if (-not $match.Success) {
                continue
            }

            $jsonText = $match.Groups['json'].Value.Trim()
            try {
                $null = $jsonText | ConvertFrom-Json -ErrorAction Stop
            } catch {
                throw "Function '$name' has an Expected output: block that is not valid JSON: $($_.Exception.Message)`nPayload was:`n$jsonText"
            }

            $cases.Add(@{
                FunctionName = $name
                Code         = ($example.code -join "`n").Trim()
                ExpectedJson = $jsonText
            })
        }
    }

    return $cases.ToArray()
}

function Get-FogMockResponse {
    <#
    .SYNOPSIS
    Fixture lookup table standing in for a real Fog server's responses.

    .DESCRIPTION
    Keyed on the core-object-type portion of the uriPath plus the HTTP
    method, since one fixture is reused across many wrapper functions that
    all funnel through Invoke-FogApi. Throws a clear error for an unmapped
    combination rather than silently returning $null, so a gap in fixture
    coverage fails loudly instead of producing a confusing downstream test
    failure.

    .PARAMETER uriPath
    The uriPath Invoke-FogApi was called with.

    .PARAMETER Method
    The HTTP method Invoke-FogApi was called with.

    .PARAMETER jsonData
    The request body, if any - used to echo back a plausible "created"
    object for POSTs that create a new object.
    #>
    [CmdletBinding()]
    param (
        [string]$uriPath,
        [string]$Method,
        [string]$jsonData
    )

    function Get-Fixture([string]$name) {
        Get-Content (Join-Path $script:FixturesPath $name) -Raw | ConvertFrom-Json
    }

    switch -regex ($uriPath) {
        '^system/info$' {
            if ($Method -eq 'GET') { return Get-Fixture 'version-info.json' }
        }
        '^module$' {
            if ($Method -eq 'GET') { return Get-Fixture 'modules.json' }
        }
        '^host/\d+/task$' {
            if ($Method -eq 'POST') { return Get-Fixture 'task-create.json' }
        }
        '^host/\d+/edit$' {
            if ($Method -eq 'PUT') {
                if ([string]::IsNullOrEmpty($jsonData)) { return Get-Fixture 'host.json' }
                return $jsonData | ConvertFrom-Json
            }
        }
        '^host/\d+$' {
            if ($Method -eq 'GET') { return Get-Fixture 'host.json' }
        }
        '^host$' {
            if ($Method -eq 'GET') { return Get-Fixture 'hosts.json' }
            if ($Method -eq 'POST') {
                $created = if ([string]::IsNullOrEmpty($jsonData)) { [PSCustomObject]@{} } else { $jsonData | ConvertFrom-Json }
                $created | Add-Member -MemberType NoteProperty -Name id -Value 42 -Force
                return $created
            }
        }
        '^groupassociation$' {
            if ($Method -eq 'GET') { return Get-Fixture 'groupassociations.json' }
            if ($Method -eq 'POST') {
                $created = if ([string]::IsNullOrEmpty($jsonData)) { [PSCustomObject]@{} } else { $jsonData | ConvertFrom-Json }
                $created | Add-Member -MemberType NoteProperty -Name id -Value 77 -Force
                return $created
            }
        }
        '^groupassociation/\d+/delete$' {
            if ($Method -eq 'DELETE') { return Get-Fixture 'delete-result.json' }
        }
        '^group/search/.+$' {
            if ($Method -eq 'GET') { return Get-Fixture 'groups-search.json' }
        }
        '^group/\d+/edit$' {
            if ($Method -eq 'PUT') {
                if ([string]::IsNullOrEmpty($jsonData)) { return Get-Fixture 'groups-search.json' }
                return $jsonData | ConvertFrom-Json
            }
        }
        '^group/\d+/task$' {
            if ($Method -eq 'POST') { return Get-Fixture 'task-create.json' }
        }
        '^scheduledtask$' {
            if ($Method -eq 'POST') {
                $created = if ([string]::IsNullOrEmpty($jsonData)) { [PSCustomObject]@{} } else { $jsonData | ConvertFrom-Json }
                $created | Add-Member -MemberType NoteProperty -Name id -Value 88 -Force
                return $created
            }
        }
    }

    throw "Get-FogMockResponse: no fixture mapped for uriPath '$uriPath' with Method '$Method'"
}

function Test-FogExpectedSubset {
    <#
    .SYNOPSIS
    Recursively asserts that $Expected is a subset of $Actual.

    .DESCRIPTION
    Every scalar, property, and array element present in $Expected must be
    present and equal in $Actual, but $Actual may contain additional
    properties. This keeps documented Expected output: blocks short and
    resistant to churn as the real API returns more fields over time.
    Returns $true/$false rather than throwing, so callers can produce a
    clear Pester assertion failure message.

    .PARAMETER Actual
    The real value returned by the function under test.

    .PARAMETER Expected
    The value parsed from the function's Expected output: annotation.
    #>
    [CmdletBinding()]
    param (
        $Actual,
        $Expected
    )

    if ($null -eq $Expected) {
        return $null -eq $Actual
    }

    if ($Expected -is [System.Management.Automation.PSCustomObject]) {
        if ($null -eq $Actual) {
            return $false
        }
        foreach ($property in $Expected.PSObject.Properties) {
            $actualMember = $Actual.PSObject.Properties[$property.Name]
            if ($null -eq $actualMember) {
                return $false
            }
            if (-not (Test-FogExpectedSubset -Actual $actualMember.Value -Expected $property.Value)) {
                return $false
            }
        }
        return $true
    }

    if ($Expected -is [array]) {
        if ($null -eq $Actual -or $Actual.Count -lt $Expected.Count) {
            return $false
        }
        for ($i = 0; $i -lt $Expected.Count; $i++) {
            if (-not (Test-FogExpectedSubset -Actual $Actual[$i] -Expected $Expected[$i])) {
                return $false
            }
        }
        return $true
    }

    return $Expected -eq $Actual
}

function Get-FogParameterSetCoverage {
    <#
    .SYNOPSIS
    Reports, per function and per real parameter set, whether an example exists and is annotated.

    .DESCRIPTION
    Advisory/best-effort coverage report - not a test assertion, never throws on a gap. For each
    function, reflects on its actual parameter sets via Get-Command, then for every .EXAMPLE
    (annotated or not) uses the PowerShell parser to find which named parameters the example's
    invocation of that function binds, and matches that set against each parameter set's parameter
    list (a subset match - an example that binds no/few parameters is attributed to every
    parameter set it's consistent with, since this is informational, not a strict gate).

    .PARAMETER FunctionName
    One or more function names to report on.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$FunctionName
    )

    $records = New-Object System.Collections.Generic.List[object]

    foreach ($name in $FunctionName) {
        $command = Get-Command -Name $name -ErrorAction SilentlyContinue
        if ($null -eq $command -or $null -eq $command.ParameterSets -or $command.ParameterSets.Count -eq 0) {
            continue
        }

        $parameterSets = $command.ParameterSets
        $setParams = @{}
        if ($parameterSets.Count -eq 1 -and $parameterSets[0].Name -eq '__AllParameterSets') {
            $setParams['Default'] = @($parameterSets[0].Parameters.Name)
        } else {
            foreach ($set in $parameterSets) {
                $setParams[$set.Name] = @($set.Parameters.Name)
            }
        }

        $aliasNames = @(Get-Alias -Definition $name -ErrorAction SilentlyContinue | ForEach-Object Name)
        $matchNames = @($name) + $aliasNames

        $help = Get-Help -Name $name -Full
        $examples = @($help.Examples.Example)

        $setHasExample = @{}
        $setHasAnnotation = @{}
        foreach ($setName in $setParams.Keys) {
            $setHasExample[$setName] = $false
            $setHasAnnotation[$setName] = $false
        }

        foreach ($example in $examples) {
            $code = ($example.code -join "`n").Trim()
            $remarksText = ($example.remarks | ForEach-Object { $_.Text }) -join "`n"
            $isAnnotated = [bool]([regex]::IsMatch($remarksText, '(?ms)^\s*Expected output:\s*\r?\n'))

            $usedParams = New-Object System.Collections.Generic.List[string]
            try {
                $parseErrors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$null, [ref]$parseErrors)
                $commandAsts = $ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -and ($matchNames -contains $node.GetCommandName())
                }, $true)
                foreach ($cmdAst in $commandAsts) {
                    $cmdAst.CommandElements |
                        Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] } |
                        ForEach-Object { $usedParams.Add($_.ParameterName) }
                }
            } catch {
                Write-Warning "Get-FogParameterSetCoverage: could not parse an example for '$name': $($_.Exception.Message)"
            }
            $uniqueUsedParams = @($usedParams | Select-Object -Unique)

            foreach ($setName in $setParams.Keys) {
                $isSubset = $true
                foreach ($p in $uniqueUsedParams) {
                    if ($setParams[$setName] -notcontains $p) {
                        $isSubset = $false
                        break
                    }
                }
                if ($isSubset) {
                    $setHasExample[$setName] = $true
                    if ($isAnnotated) {
                        $setHasAnnotation[$setName] = $true
                    }
                }
            }
        }

        foreach ($setName in ($setParams.Keys | Sort-Object)) {
            $records.Add([PSCustomObject]@{
                FunctionName  = $name
                ParameterSet  = $setName
                HasExample    = $setHasExample[$setName]
                HasAnnotation = $setHasAnnotation[$setName]
            })
        }
    }

    return $records.ToArray()
}

function ConvertTo-FogCoverageMarkdown {
    <#
    .SYNOPSIS
    Formats Get-FogParameterSetCoverage records as a markdown checklist.

    .DESCRIPTION
    Groups by function, one checkbox line per parameter set: checked when an example is annotated
    with Expected output:, unchecked (with a reason) when an example exists but isn't annotated, or
    when no example targets that set at all. Purely a formatter - has no opinion on whether the
    result is "good enough"; that judgment is left to whoever reads the report.

    .PARAMETER Coverage
    Records produced by Get-FogParameterSetCoverage.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Coverage
    )

    $total = $Coverage.Count
    $annotated = @($Coverage | Where-Object HasAnnotation).Count

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# FogApi Expected output: coverage report')
    $lines.Add('')
    $lines.Add("$annotated / $total parameter sets have an annotated ``Expected output:`` example.")
    $lines.Add('')
    $lines.Add('This is an informational report, not a pass/fail gate - see docs/Contributing.md.')
    $lines.Add('')

    $byFunction = $Coverage | Group-Object FunctionName | Sort-Object Name

    foreach ($group in $byFunction) {
        $lines.Add("## $($group.Name)")
        $lines.Add('')
        foreach ($record in ($group.Group | Sort-Object ParameterSet)) {
            if ($record.HasAnnotation) {
                $lines.Add("- [x] $($record.ParameterSet)")
            } elseif ($record.HasExample) {
                $lines.Add("- [ ] $($record.ParameterSet) - example exists, not annotated with Expected output:")
            } else {
                $lines.Add("- [ ] $($record.ParameterSet) - no example")
            }
        }
        $lines.Add('')
    }

    return ($lines -join "`n")
}

function Register-FogApiMock {
    <#
    .SYNOPSIS
    Installs the Invoke-FogApi mock for the FogApi module.

    .DESCRIPTION
    Meant to be called from inside a Pester It/BeforeEach block. Skips
    installing any mock when -RealServer is set, so the exact same example
    invocation runs against a real, already-configured Fog server instead.

    .PARAMETER RealServer
    When set, does nothing - the caller's example runs unmocked.
    #>
    [CmdletBinding()]
    param (
        [switch]$RealServer
    )

    if ($RealServer) {
        return
    }

    Mock -ModuleName FogApi Invoke-FogApi {
        Get-FogMockResponse -uriPath $uriPath -Method $Method -jsonData $jsonData
    }
}

Export-ModuleMember -Function Get-FogExampleCase, Get-FogMockResponse, Test-FogExpectedSubset, Register-FogApiMock, Get-FogParameterSetCoverage, ConvertTo-FogCoverageMarkdown
