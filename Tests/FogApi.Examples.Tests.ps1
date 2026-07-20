#
# Data-driven tests built from the "Expected output:" annotations inside
# the module's own comment-based help .EXAMPLE blocks (see
# Tests/FogApi.TestHelpers.psm1 for the parsing/mocking convention).
#
# By default Invoke-FogApi is mocked with fixture data (Tests/Fixtures/) so
# this runs fast and deterministically with no external dependency. Pass
# -Data @{ RealServer = $true } via New-PesterContainer to instead run
# these same examples, unmocked, against a real configured Fog server.
#
param(
    [switch]$RealServer,
    [string[]]$Function,
    [string]$CoverageReportPath
)

BeforeDiscovery {
    $moduleManifest = Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1'
    Import-Module $moduleManifest -Force
    Import-Module (Join-Path $PSScriptRoot 'FogApi.TestHelpers.psm1') -Force

    # Pilot function list - see the plan doc for why these were chosen.
    # Invoke-FogApi itself is covered by its own dedicated test file
    # (Tests/Invoke-FogApi.Tests.ps1) since it can't be tested by mocking
    # itself. -Function narrows this down further for a targeted local run.
    $script:FogPilotFunctions = @(
        'Get-FogObject',
        'Get-FogHost',
        'Get-FogHosts',
        'New-FogHost',
        'Update-FogObject',
        'New-FogObject',
        'Send-FogWolTask',
        'Test-StringNotNullOrEmpty',
        'Add-FogHostGroup',
        'Remove-FogHostGroup',
        'Update-FogGroup',
        'Send-FogGroupTask',
        'Add-FogHostMac',
        'Get-FogHostMacs',
        'Get-FogHostPendingMacs',
        'Approve-FogPendingMac',
        'Deny-FogPendingMac',
        'Get-FogMacAddresses',
        'Remove-UsbMac',
        'Get-FogHostGroup',
        'Set-FogHostImage',
        'Reset-HostEncryption',
        'Get-FogGroups',
        'Get-FogGroupByName',
        'Get-FogGroupAssociations',
        'Get-FogImages',
        'Receive-FogImage',
        'Send-FogImage',
        'Get-FogSnapins',
        'Get-FogSnapinAssociations',
        'Get-FogHostAssociatedSnapins',
        'Repair-FogSnapinAssociations',
        'Set-FogSnapins',
        'Start-FogSnapins',
        'Start-FogSnapin',
        'Get-FogModules',
        'Get-FogSettings',
        'Get-FogSetting',
        'Set-FogSetting',
        'Get-FogActiveTasks',
        'Get-FogScheduledTasks',
        'Remove-FogObject',
        'Find-FogObject',
        'Add-FogResultData',
        'Get-LastImageTime',
        'Test-FogVerAbove1dot6',
        'Get-FogVersion'
    )
    if ($Function) {
        $script:FogPilotFunctions = $script:FogPilotFunctions | Where-Object { $_ -in $Function }
    }
    $script:FogExampleCases = Get-FogExampleCase -FunctionName $script:FogPilotFunctions
}

Describe 'FogApi documented examples' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1') -Force
        Import-Module (Join-Path $PSScriptRoot 'FogApi.TestHelpers.psm1') -Force
    }

    It '<FunctionName>: <Code>' -ForEach $script:FogExampleCases {
        Register-FogApiMock -RealServer:$RealServer

        $actual = Invoke-Expression -Command $Code
        $expected = $ExpectedJson | ConvertFrom-Json

        $isSubset = Test-FogExpectedSubset -Actual $actual -Expected $expected
        $isSubset | Should -BeTrue -Because "documented Expected output: was:`n$ExpectedJson`n`nactual output was:`n$($actual | ConvertTo-Json -Depth 6)"
    }
}
