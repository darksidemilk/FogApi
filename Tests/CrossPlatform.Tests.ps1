#
# Cross-platform correctness tests.
#
# The module declares CompatiblePSEditions Core and describes itself as a
# crossplatform cli for fog, but nothing verified that claim - CI ran on
# windows only, and the mocked fixtures assume a settings file already exists,
# so the first-run bootstrap path was never exercised anywhere.
#
# These are deliberately not example-derived. They assert behaviour that only
# shows up on a platform or in a state the example suite cannot reach.
#
# Accepts the same container Data as the other files under Tests/ (see
# Invoke-FogApiTests.ps1) even though it doesn't use them, so a shared
# New-PesterContainer -Data call doesn't fail parameter binding here.
#
param(
    [switch]$RealServer,
    [string[]]$Function,
    [string]$CoverageReportPath
)

BeforeAll {
    $moduleManifest = Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1'
    Import-Module $moduleManifest -Force
}

Describe 'Module paths are separator agnostic' {

    It 'builds $script:lib into a path that resolves on this platform' {
        # "$PSModuleRoot\lib" resolves on windows but is a literal filename containing
        # a backslash on linux/mac, which broke the settings bootstrap that every
        # command funnels through. Backslashes are legitimate on windows, so the
        # separator itself is only asserted on posix.
        $libPath = InModuleScope FogApi { $script:lib }
        $libPath | Should -Not -BeNullOrEmpty
        Test-Path $libPath | Should -BeTrue -Because 'the lib folder ships with the module'
        if ($IsLinux -or $IsMacOS) {
            $libPath | Should -Not -Match '\\' -Because 'a backslash in a posix path means a hardcoded separator'
        }
    }

    It 'can read the settings template that the bootstrap copies from' {
        $template = InModuleScope FogApi { Join-Path $script:lib 'settings.json' }
        Test-Path $template | Should -BeTrue
        { Get-Content $template -Raw | ConvertFrom-Json } | Should -Not -Throw
    }

    It 'exposes a single posix test so a branch cannot cover linux and forget mac' {
        $isPosix = InModuleScope FogApi { $script:IsPosix }
        $isPosix | Should -BeOfType [bool]
        $isPosix | Should -Be ($IsLinux -or $IsMacOS)
    }

    It 'has no source file building a module path with a hardcoded backslash' {
        $moduleRoot = Join-Path $PSScriptRoot '..' 'FogApi'
        $offenders = Get-ChildItem $moduleRoot -Recurse -Filter '*.ps1' |
            Select-String -Pattern '\$script:(lib|bin|tools)\\' |
            ForEach-Object { "$($_.Filename):$($_.LineNumber)" }
        $offenders | Should -BeNullOrEmpty
    }
}

Describe 'Get-FogHost identity matching' {

    Context 'when the local machine identity cannot be determined' {
        BeforeEach {
            # This is the state pwsh on linux lands in: no CIM, so no uuid and no mac.
            Mock -ModuleName FogApi Get-FogLocalIdentity {
                [PSCustomObject]@{ uuid = $null; macAddress = $null; macAddresses = @(); hostName = $null }
            }
            Mock -ModuleName FogApi Get-FogHosts {
                @(
                    [PSCustomObject]@{ id = 1; name = 'HostWithNoInventory'; macs = @(); inventory = [PSCustomObject]@{ sysuuid = $null } }
                    [PSCustomObject]@{ id = 2; name = 'AnotherWithNoInventory'; macs = @(); inventory = [PSCustomObject]@{ sysuuid = $null } }
                )
            }
        }

        It 'does not match every host that happens to have no inventory uuid' {
            # The guard used to be '$uuid -ne ""'. $null -ne "" is $true, so a null search
            # term degenerated into 'sysuuid -eq $null' and matched all of these. Callers
            # feed the result straight into Update-FogObject, so this wrote to a wrong host.
            $result = Get-FogHost -ErrorAction SilentlyContinue
            $result | Should -Be $false
        }

        It 'reports why rather than failing obscurely' {
            $err = $null
            Get-FogHost -ErrorAction SilentlyContinue -ErrorVariable err | Out-Null
            "$err" | Should -Match 'search terms'
        }
    }

    Context 'when the local machine identity is available' {
        BeforeEach {
            Mock -ModuleName FogApi Get-FogLocalIdentity {
                [PSCustomObject]@{
                    uuid = 'AAAA-BBBB'; macAddress = '00:11:22:33:44:55'
                    macAddresses = @('00:11:22:33:44:55'); hostName = 'MeowMachine'
                }
            }
            Mock -ModuleName FogApi Get-FogHosts {
                @(
                    [PSCustomObject]@{ id = 1; name = 'Other'; macs = @(); inventory = [PSCustomObject]@{ sysuuid = $null }; ADOU = '' }
                    [PSCustomObject]@{ id = 42; name = 'MeowMachine'; macs = @('00:11:22:33:44:55'); inventory = [PSCustomObject]@{ sysuuid = 'AAAA-BBBB' }; ADOU = '' }
                )
            }
        }

        It 'still finds the right host' {
            (Get-FogHost).id | Should -Be 42
        }
    }
}

Describe 'Get-FogLocalIdentity' {

    It 'returns the expected shape on this platform' {
        $identity = InModuleScope FogApi { Get-FogLocalIdentity }
        $identity.PSObject.Properties.Name | Should -Contain 'uuid'
        $identity.PSObject.Properties.Name | Should -Contain 'macAddress'
        $identity.PSObject.Properties.Name | Should -Contain 'macAddresses'
        $identity.PSObject.Properties.Name | Should -Contain 'hostName'
    }

    It 'reports unknown values as $null rather than empty string' {
        # Get-FogHost distinguishes "unknown" from "known to be blank", so an
        # empty string here would put the wrong-host bug straight back.
        $identity = InModuleScope FogApi { Get-FogLocalIdentity }
        foreach ($prop in 'uuid', 'macAddress', 'hostName') {
            if ($null -ne $identity.$prop) {
                $identity.$prop | Should -Not -BeNullOrEmpty
            }
        }
    }

    It 'resolves a hostname on any platform' {
        (InModuleScope FogApi { Get-FogLocalIdentity }).hostName | Should -Not -BeNullOrEmpty
    }
}

Describe 'Platform guards on windows-only functions' {

    # Each of these must fail cleanly on a platform it does not support, rather
    # than erroring out of a native call. Dismount-WinEfi had no guard at all,
    # and Get-WinBcdPxeID warned but then fell out of its process block without
    # returning anything.
    It '<Name> returns null on posix instead of erroring' -ForEach @(
        @{ Name = 'Get-WinEfiMountLetter' }
        @{ Name = 'Mount-WinEfi' }
        @{ Name = 'Dismount-WinEfi' }
        @{ Name = 'Get-WinBcdPxeID' }
        @{ Name = 'Set-WinToBootToPxe' }
    ) {
        if (-not ($IsLinux -or $IsMacOS)) {
            Set-ItResult -Skipped -Because 'this asserts the posix guard, and this is windows'
            return
        }
        { & $Name -WarningAction SilentlyContinue } | Should -Not -Throw
        (& $Name -WarningAction SilentlyContinue) | Should -BeNullOrEmpty
    }

    It 'Get-EfiMountLetter resolves, since Mount-WinEfi and Dismount-WinEfi both call it by that name' {
        # Neither function ever worked - the function is named Get-WinEfiMountLetter
        # and carried no alias, so this was broken on windows too.
        Get-Command Get-EfiMountLetter -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe 'Settings file bootstrap' {

    It 'derives a settings path appropriate to this platform' {
        $settingsFile = Get-FogServerSettingsFile
        $settingsFile | Should -Not -BeNullOrEmpty
        if ($IsLinux -or $IsMacOS) {
            $settingsFile | Should -Match '\.FogApi'
            $settingsFile | Should -Not -Match '\\'
        }
        Split-Path $settingsFile -Leaf | Should -Be 'api-settings.json'
    }

    It 'does not change the caller working directory' {
        # Get-FogServerSettings used to Set-Location its way down the tree while
        # creating the parent folder, leaving the caller somewhere else entirely.
        $before = (Get-Location).Path
        $null = Get-FogServerSettings -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        (Get-Location).Path | Should -Be $before
    }
}
