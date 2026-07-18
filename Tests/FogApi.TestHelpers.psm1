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

Export-ModuleMember -Function Get-FogExampleCase, Get-FogMockResponse, Test-FogExpectedSubset, Register-FogApiMock
