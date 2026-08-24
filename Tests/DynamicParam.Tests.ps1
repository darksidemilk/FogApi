#
# The dynamic -coreObject parameter has to exist without the caller naming -type.
#
# A DynamicParam block is handed only the BOUND parameters, never a parameter's
# default. Every L1 function writes `Set-DynamicParams $type`, so a caller who
# omits -type leaves $type null, the switch inside Set-DynamicParams matches
# nothing, and -coreObject is never added.
#
# What makes that worth a test rather than a comment is the error it produces:
#
#     A parameter cannot be found that matches parameter name 'coreObject'.
#
# It names the parameter that is missing instead of the one that caused it to be
# missing, so it reads as "coreObject is wrong" when the answer is "-type was
# not supplied". Find-FogObject was the worst case, because -type there carries
# a default of 'search' and so looks optional -- meaning
# `Find-FogObject -coreObject host -stringToSearch x` has never worked, despite
# nothing in the signature suggesting it would not.
#
# Find-FogObject and Update-FogObject both declare a ValidateSet of exactly one
# value, so their DynamicParam blocks pass that literal and no longer consult
# $type. The other three take a genuine multi-value -type that really does
# select which dynamic parameter appears, so they still require it; they are
# asserted here too, as documentation of the difference rather than as a defect.
#
Describe 'dynamic -coreObject binding' {

    BeforeAll {
        # Pester 6 refuses Mock -ModuleName when two modules share a name, and each
        # test file importing into its own scope makes that happen across a run.
        Remove-Module FogApi -Force -ErrorAction SilentlyContinue
        Import-Module (Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1') -Force

        function Test-CoreObjectBinds {
            <#
            True when -coreObject can be bound without naming -type.

            Binding is exercised rather than inspected: Get-Command reports the
            static parameters, and the whole question here is about a dynamic
            one. A deliberately invalid -coreObject value is used so the binder
            has to resolve the parameter and its ValidateSet, and the call fails
            during binding rather than reaching the network.
            #>
            param([string]$Name, [string]$Type)
            $splat = @{ coreObject = '~nosuchclass~'; ErrorAction = 'Stop' }
            if ($Type) { $splat.type = $Type }
            try {
                & $Name @splat 2>&1 | Out-Null
            } catch {
                # "cannot be found that matches parameter name 'coreObject'" is
                # the only failure that means the parameter was never added.
                # Anything else -- a ValidateSet complaint, or a failed version
                # probe while the set was being built -- means it WAS added,
                # which is the whole assertion.
                if ($_.Exception.Message -match "matches parameter name 'coreObject'") {
                    return $false
                }
            }
            return $true
        }
    }

    Context 'a -type of exactly one legal value is not worth asking for' {
        It '<_> binds -coreObject with no -type' -ForEach @('Find-FogObject', 'Update-FogObject') {
            Test-CoreObjectBinds -Name $_ | Should -BeTrue -Because @'
its DynamicParam block must pass the literal from its own ValidateSet rather
than $type, which is always null there unless the caller named it
'@
        }

        It '<Fn> still accepts an explicit -type, so no caller breaks' -ForEach @(
            @{ Fn = 'Find-FogObject';   Type = 'search' }
            @{ Fn = 'Update-FogObject'; Type = 'object' }
        ) {
            # Asserted as "-coreObject was found", not as "the ValidateSet
            # rejected the value". Building the set calls Get-FogVersion, which
            # is a real request -- so an assertion on the rejection message only
            # passes when a server happens to be reachable, and this suite is
            # the mocked gate. It failed exactly that way once.
            #
            # Get-DynmicParam calling Get-FogVersion during binding is the
            # round-trip cost noted for phase 0.5; until that is fixed, a test
            # at this layer cannot assume the parameter's contents offline. What
            # it can assume is that the parameter exists to be bound.
            Test-CoreObjectBinds -Name $Fn -Type $Type | Should -BeTrue
        }
    }

    Context 'a -type that genuinely selects still has to be supplied' {
        # Not a defect: -type picks between coreObject, coreTaskObject and
        # coreActiveTaskObject on these, so there is no single literal to use.
        # Asserted so that changing it is a deliberate act with a failing test
        # attached, not a silent drift.
        It '<_> requires -type before -coreObject exists' -ForEach @(
            'Get-FogObject', 'New-FogObject', 'Remove-FogObject'
        ) {
            Test-CoreObjectBinds -Name $_ | Should -BeFalse
        }
    }
}
