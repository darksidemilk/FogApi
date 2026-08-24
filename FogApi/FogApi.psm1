$PSModuleRoot = $PSScriptRoot
# Join-Path, not "$PSModuleRoot\lib" - on linux and mac a backslash is a literal
# filename character, so the hardcoded separator produced a path that never
# resolved and broke the settings file bootstrap that every command depends on
$script:lib = Join-Path $PSModuleRoot 'lib'
$script:bin = Join-Path $PSModuleRoot 'bin'

# --- the compiled core ------------------------------------------------------
#
# The manifest names bin/FogApi.Core.dll in RequiredAssemblies, which loads it BEFORE
# nested modules and before this file, so the compiled types are already here.
# This guard is for the other entry point: build.ps1 has always loaded the module
# with Import-Module on the .psm1 directly, which bypasses the manifest and
# therefore bypasses RequiredAssemblies.
if (-not ('FogApi.FogTransport' -as [type])) {
    $dll = Join-Path $script:bin 'FogApi.Core.dll'
    if (-not (Test-Path -LiteralPath $dll)) {
        throw "FogApi's compiled core is missing from $dll. Run ./build-dotnet.ps1, or install FogApi from the PowerShell Gallery rather than importing the source tree."
    }
    Import-Module -Name $dll -ErrorAction Stop
}

# Type accelerators, so a bare [FogObjectRefTransform()] still resolves now that
# the type lives in a namespace.
#
# ORDER IS LOAD-BEARING: this has to happen before any Public/*.ps1 is
# dot-sourced, because an attribute name is resolved when the file is PARSED.
# Registering after the loop fails every function that names one, and measured:
#   [FogObjectRefTransform()]                  -> Cannot find the type
#   [FogApi.FogObjectRefTransform()]           -> resolves
#   [FogObjectRefTransform()] + accelerator    -> resolves
# The bare spelling is what the emitted files and third-party scripts use, so
# the accelerator is required rather than a convenience.
$script:TypeAcceleratorTable = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
$script:FogAccelerators = @{
    FogObjectRefTransform = [FogApi.FogObjectRefTransformAttribute]
}
foreach ($accelerator in $script:FogAccelerators.GetEnumerator()) {
    # The accelerator table is session-global, so this is a land grab. Taking a
    # name someone else registered would be worse than not having ours.
    if (-not $script:TypeAcceleratorTable::Get.ContainsKey($accelerator.Key)) {
        $script:TypeAcceleratorTable::Add($accelerator.Key, $accelerator.Value)
    }
}

$PublicFunctions = @( Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue )
$PrivateFunctions = @( Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue )
# Classes load first, matching what invoke-modulebuild.ps1 concatenates. A class
# loaded here IS usable by the functions dot-sourced below -- as a parameter type,
# a property type, a cast or a constructor. Verified on pwsh 7.4.6 against the
# loader ProvisioningMgmt uses in production.
#
# The one thing that does NOT work is a type literal as an ATTRIBUTE argument:
# [OutputType([FogHost])] fails to resolve and poisons the whole function, so
# even invoking it throws "Unable to find type". [ValidateSet([Generator])] fails
# the same way. Use the string form -- [OutputType('FogHost')] -- which resolves,
# feeds Get-Help and PlatyPS, and still returns a real class instance.
#
# Two more traps worth knowing before adding a class here: a caller outside the
# module cannot name the type without 'using module' (build.ps1:129-132 imports
# the class files from caller scope before PlatyPS, which also covers it), and
# [T]@{...} runs the default constructor BEFORE the hashtable properties are
# assigned, so never compute derived state there.
#
# A type that moves to C# leaves this folder: it gains a namespace, a caller can
# name it with no 'using module', and the attribute-argument trap above stops
# applying. FogObjectRefTransform went that way; FogTaskRequest has not yet.
$ClassFiles = @( Get-ChildItem -Path "$PSScriptRoot/Classes/*.ps1" -ErrorAction SilentlyContinue )


foreach ($file in @($ClassFiles + $PublicFunctions + $PrivateFunctions)) {
    try {
        . $file.FullName
    }
    catch {
        $exception = ([System.ArgumentException]"Function not found")
        $errorId = "Load.Function"
        $errorCategory = 'ObjectNotFound'
        $errorTarget = $file
        $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
        $errorItem.ErrorDetails = "Failed to import function $($file.BaseName)"
        throw $errorItem
    }
}
# Register ETS type data for FOG object types. After the dot-sourcing loop so the
# function exists. invoke-modulebuild.ps1 re-emits this call into the built psm1,
# which is generated and does not inherit this file's body.
Register-FogTypeData

# Session-global accelerators outlive the module unless we hand them back.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    foreach ($name in $script:FogAccelerators.Keys) {
        $script:TypeAcceleratorTable::Remove($name)
    }
}

# -Cmdlet * is load-bearing. Export-ModuleMember's contract is that only what it
# names is exported, so the old line -- which named -Function and -Alias only --
# would export the script functions and NONE of the compiled cmdlets, silently.
Export-ModuleMember -Function $PublicFunctions.BaseName -Cmdlet * -Alias *
