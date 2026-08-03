#
# Hand-written integration tests exercising real behavior/contracts against an actual, configured
# Fog server - deliberately NOT derived from doc examples (see FogApi.Examples.Tests.ps1, which
# stays mocked-only). Doc examples are illustrative: their "Expected output:" blocks are fixed
# values authored to match Tests/Fixtures/, so a real server's actual version/settings/inventory
# will essentially never match them even when a call succeeds, and most examples also reference
# fixture-only ids/names (host 42, group 7) that plainly won't exist on any given real server.
# Rather than forcing those same examples to somehow pass against arbitrary real data, this suite
# dynamically creates/discovers its own real objects and asserts real contracts (round-trips,
# structural shape) instead of specific illustrative values. Uses the same recording/journal
# safety net as everything else - see Tests/FogApi.TestHelpers.psm1 and docs/Contributing.md.
#
# Each Context that needs a real host/group creates its own, in its own Context-scoped BeforeAll,
# rather than sharing one Describe-level setup - so a creation failure in one Context (a real
# server rejecting a payload, a transient error) only fails that Context's tests, not every test
# in the file, including read-only ones that never needed a host in the first place.
#
# Entirely skipped unless run with -RealServer (.\Invoke-FogApiTests.ps1 -RealServer); needs a
# real, already-configured Fog server (see Get-FogServerSettings / api-settings.json).
#
param(
    [switch]$RealServer,
    [string]$RealServerJournalPath = (Join-Path $PSScriptRoot '..' 'TestResults' 'realserver-journal.ndjson')
)

Describe 'FogApi real-server integration' -Skip:(-not $RealServer) {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1') -Force
        Import-Module (Join-Path $PSScriptRoot 'FogApi.TestHelpers.psm1') -Force

        # Must run before Invoke-FogApi is mocked for the first time this session, while
        # Get-Command can still resolve the true implementation - see
        # Initialize-FogRealServerJournal's help for why.
        Initialize-FogRealServerJournal -JournalPath $RealServerJournalPath
        Register-FogApiMock -RealServer

        function script:New-FogRealServerTestName {
            param([string]$Prefix)
            # A unique suffix per call - never reuses a name, so this can never collide with (or
            # accidentally delete) anything genuinely part of the server's real inventory.
            "$Prefix-$(Get-Random -Minimum 100000 -Maximum 999999)"
        }

        function script:New-FogRealServerTestMac {
            "02:FA:{0:X2}:{1:X2}:{2:X2}:{3:X2}" -f (Get-Random -Maximum 256), (Get-Random -Maximum 256), (Get-Random -Maximum 256), (Get-Random -Maximum 256)
        }
    }

    AfterAll {
        # Always runs, whether or not the tests above passed - a mutation this run caused needs
        # reverting regardless of whether the test that caused it happened to fail.
        $summary = Restore-FogRealServerState -JournalPath $RealServerJournalPath

        Write-Host "`n--- Real-server cleanup summary ($RealServerJournalPath) ---" -ForegroundColor Cyan
        foreach ($line in $summary.Restored) { Write-Host "  [reverted] $line" -ForegroundColor Green }
        foreach ($line in $summary.FailedToRestore) { Write-Warning "[FAILED TO REVERT] $line" }
        foreach ($line in $summary.Unrevertable) { Write-Warning "[CANNOT AUTO-REVERT] $line" }
        if (-not $summary.Restored -and -not $summary.FailedToRestore -and -not $summary.Unrevertable) {
            Write-Host "  no mutating calls were made" -ForegroundColor Green
        }
    }

    Context 'Connectivity' {
        It 'Get-FogVersion returns a non-empty version string' {
            $version = Get-FogVersion
            $version | Should -Not -BeNullOrEmpty
            $version | Should -BeOfType [string]
        }

        It 'Test-FogVerAbove1dot6 returns a boolean' {
            Test-FogVerAbove1dot6 | Should -BeOfType [bool]
        }
    }

    Context 'Host lifecycle' {
        BeforeAll {
            $script:runSuffix = Get-Random -Minimum 100000 -Maximum 999999
            $script:testHostName = New-FogRealServerTestName -Prefix 'FogApiTest'
            $script:testHostMac = New-FogRealServerTestMac
            Write-Host "`n--- Host lifecycle: creating '$($script:testHostName)' / $($script:testHostMac) ---" -ForegroundColor Cyan
            $script:testHost = New-FogHost -name $script:testHostName -macs $script:testHostMac
        }

        It 'created a real host with a real id' {
            $script:testHost | Should -Not -BeNullOrEmpty
            "$($script:testHost.id)" | Should -Match '^\d+$'
        }

        It 'Get-FogHost finds the created host by name' {
            $found = Get-FogHost -hostName $script:testHostName
            $found | Should -Not -BeNullOrEmpty
            $found.name | Should -Be $script:testHostName
        }

        It 'Get-FogHosts includes the created host' {
            $all = Get-FogHosts
            ($all | Where-Object id -eq $script:testHost.id) | Should -Not -BeNullOrEmpty
        }

        It 'Update-FogObject changes a field and Get-FogHost reflects it back' {
            $newAdUser = "svc-test-$($script:runSuffix)"
            Update-FogObject -type object -coreObject host -IDofObject $script:testHost.id -jsonData (@{ ADUser = $newAdUser } | ConvertTo-Json -Compress) | Out-Null
            $updated = Get-FogHost -hostID $script:testHost.id
            $updated.ADUser | Should -Be $newAdUser
        }
    }

    Context 'Host mac lifecycle' {
        BeforeAll {
            $script:macHostName = New-FogRealServerTestName -Prefix 'FogApiTest-Mac'
            $script:macHostMac = New-FogRealServerTestMac
            $script:secondMac = New-FogRealServerTestMac
            Write-Host "`n--- Host mac lifecycle: creating '$($script:macHostName)' / $($script:macHostMac) ---" -ForegroundColor Cyan
            $script:macHost = New-FogHost -name $script:macHostName -macs $script:macHostMac
        }

        It 'Add-FogHostMac adds a second mac and Get-FogHostMacs reflects it' {
            Add-FogHostMac -hostID $script:macHost.id -macAddress $script:secondMac | Out-Null
            $macs = Get-FogHostMacs -hostID $script:macHost.id
            ($macs.mac -contains $script:secondMac) | Should -BeTrue
        }
    }

    Context 'Group lifecycle' {
        BeforeAll {
            $script:groupRunSuffix = Get-Random -Minimum 100000 -Maximum 999999
            $script:groupHostName = New-FogRealServerTestName -Prefix 'FogApiTest-GroupHost'
            $script:groupHostMac = New-FogRealServerTestMac
            $script:testGroupName = New-FogRealServerTestName -Prefix 'FogApiTest-Group'
            Write-Host "`n--- Group lifecycle: creating '$($script:groupHostName)' and group '$($script:testGroupName)' ---" -ForegroundColor Cyan
            $script:groupHost = New-FogHost -name $script:groupHostName -macs $script:groupHostMac
            $script:testGroup = New-FogObject -type object -coreObject group -jsonData (@{ name = $script:testGroupName; description = 'FogApi -RealServer integration test group' } | ConvertTo-Json -Compress)
        }

        It 'created a real group with a real id' {
            $script:testGroup | Should -Not -BeNullOrEmpty
            "$($script:testGroup.id)" | Should -Match '^\d+$'
        }

        It 'Add-FogHostGroup associates the host and Get-FogHostGroup reflects it' {
            Add-FogHostGroup -hostID $script:groupHost.id -groupID $script:testGroup.id | Out-Null
            $groups = @(Get-FogHostGroup -hostId $script:groupHost.id)
            ($groups.id -contains $script:testGroup.id) | Should -BeTrue
        }

        It 'Update-FogGroup changes the description' {
            $newDescription = "Updated by FogApi -RealServer test run $($script:groupRunSuffix)"
            Update-FogGroup -groupID $script:testGroup.id -Description $newDescription | Out-Null
            $found = Get-FogGroupByName -groupName ([regex]::Escape($script:testGroupName))
            $found.description | Should -Be $newDescription
        }

        It 'Remove-FogHostGroup removes the association' {
            Remove-FogHostGroup -hostID $script:groupHost.id -groupID $script:testGroup.id | Out-Null
            $groups = @(Get-FogHostGroup -hostId $script:groupHost.id)
            ($groups.id -contains $script:testGroup.id) | Should -BeFalse
        }
    }

    Context 'Read-only structural contracts' {
        # These deliberately check shape (right fields present, right types), not specific
        # values - a real server's actual version/settings/inventory belongs to whoever owns
        # that server, not to this test suite. No setup needed - these run independently of
        # whether host/group creation above succeeded.

        It 'Get-FogSettings returns an array of id/name-shaped settings' {
            $settings = @(Get-FogSettings)
            $settings.Count | Should -BeGreaterThan 0
            $settings[0].PSObject.Properties.Name | Should -Contain 'id'
            $settings[0].PSObject.Properties.Name | Should -Contain 'name'
        }

        It 'Get-FogSetting resolves a known setting by name' {
            $setting = Get-FogSetting -settingName 'FOG_WEB_HOST'
            $setting | Should -Not -BeNullOrEmpty
            $setting.name | Should -Be 'FOG_WEB_HOST'
        }

        It 'Get-FogModules returns an array of id/name-shaped modules' {
            $modules = @(Get-FogModules)
            $modules.Count | Should -BeGreaterThan 0
            $modules[0].PSObject.Properties.Name | Should -Contain 'id'
        }

        It 'Get-FogSnapins does not throw' {
            { Get-FogSnapins } | Should -Not -Throw
        }

        It 'Get-FogImages does not throw' {
            { Get-FogImages } | Should -Not -Throw
        }

        It 'Get-FogVersion is at least major version 1' {
            (Get-FogVersion) | Should -Match '^\d+\.'
        }
    }
}
