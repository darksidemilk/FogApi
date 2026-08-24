#
# Data-driven tests built from the "Expected output:" annotations inside
# the module's own comment-based help .EXAMPLE blocks (see
# Tests/FogApi.TestHelpers.psm1 for the parsing/mocking convention).
#
# Always runs against fixture data (Tests/Fixtures/) via a mocked Invoke-FogApi, fast and
# deterministic with no external dependency - this is the primary CI gate. It is intentionally
# NOT run against a real Fog server: the "Expected output:" annotations are illustrative, fixed
# values authored to match the fixtures, and would almost never match a real server's actual
# version/settings/inventory even when a call succeeds. Real-server validation instead lives in
# Tests/FogApi.RealServer.Tests.ps1, a hand-written suite that asserts real behavior/contracts
# (round-trips, structural shape) rather than specific illustrative values - see
# docs/Contributing.md for why.
#
param(
    [string[]]$Function,
    [string]$CoverageReportPath
)

BeforeDiscovery {
    $moduleManifest = Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1'
    Import-Module $moduleManifest -Force
    Import-Module (Join-Path $PSScriptRoot 'FogApi.TestHelpers.psm1') -Force

    # Every exported function, minus a short exclusion list.
    #
    # This was a hardcoded inclusion list of 46 names, which had the failure mode
    # that matters least when nothing is being added and most when things are:
    # a new function got zero tests and said nothing about it. Generated cmdlets
    # arrive dozens at a time, so an inclusion list would have quietly left the
    # whole generated surface untested.
    #
    # Inverted, a function is covered the moment it exists, and skipping one is
    # a line somebody has to write and a reviewer can see.
    $script:FogExcludedFromExamples = @{
        # Cannot be tested by mocking itself; has its own file.
        'Invoke-FogApi'                     = 'covered by Tests/Invoke-FogApi.Tests.ps1'
        # Read or write the local settings file rather than calling the API.
        'Get-FogServerSettings'             = 'reads the local settings file'
        'Set-FogServerSettings'             = 'writes the local settings file, and prompts'
        'Get-FogServerSettingsFile'         = 'returns a local path'
        'Set-FogServerSettingsFileSecurity' = 'sets local file permissions'
        'Enable-FogApiHTTPS'                = 'rewrites the local settings file'
        'Disable-FogApiHTTPS'               = 'rewrites the local settings file'
        # Windows-only local system operations with no API call to mock.
        'Install-FogService'                = 'installs a Windows service'
        'Mount-WinEfi'                      = 'mounts the local EFI partition'
        'Dismount-WinEfi'                   = 'unmounts the local EFI partition'
        'Get-WinEfiMountLetter'             = 'reads local disk state'
        'Get-WinBcdPxeID'                   = 'reads the local BCD store'
        'Set-WinToBootToPxe'                = 'writes the local BCD store'
        'Get-FogInventory'                  = 'collects hardware from the local machine'
        'Set-FogInventory'                  = 'reads the local machine before writing'
        'Get-FogLog'                        = 'reads a local log file'
        # Pure local helpers with no API call.
        'Get-FogSecsSinceEpoch'             = 'returns the current time'
        'Resolve-HostID'                    = 'resolves against the current host'
        # Pager internals, asserted on request sequence instead.
        'Get-FogPagedResult'                = 'covered by Tests/Get-FogPagedResult.Tests.ps1'
    }
    $exported = @((Get-Module FogApi).ExportedFunctions.Keys)
    $script:FogPilotFunctions = @(
        $exported | Where-Object { -not $script:FogExcludedFromExamples.ContainsKey($_) } | Sort-Object
    )
    if ($Function) {
        $script:FogPilotFunctions = $script:FogPilotFunctions | Where-Object { $_ -in $Function }
    }
    $script:FogExampleCases = Get-FogExampleCase -FunctionName $script:FogPilotFunctions
}

Describe 'FogApi documented examples' {
    BeforeAll {
        # Pester 6 refuses Mock -ModuleName when two modules share a name, and each
        # test file importing into its own scope makes that happen across a run.
        Remove-Module FogApi -Force -ErrorAction SilentlyContinue
        Import-Module (Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1') -Force
        Import-Module (Join-Path $PSScriptRoot 'FogApi.TestHelpers.psm1') -Force
    }

    It '<FunctionName>: <Code>' -ForEach $script:FogExampleCases {
        Register-FogApiMock

        $actual = Invoke-Expression -Command $Code
        $expected = $ExpectedJson | ConvertFrom-Json

        $isSubset = Test-FogExpectedSubset -Actual $actual -Expected $expected
        $isSubset | Should -BeTrue -Because "documented Expected output: was:`n$ExpectedJson`n`nactual output was:`n$($actual | ConvertTo-Json -Depth 6)"
    }
}
