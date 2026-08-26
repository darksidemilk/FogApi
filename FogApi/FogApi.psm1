$PSModuleRoot = $PSScriptRoot
# Join-Path, not "$PSModuleRoot\lib" - on linux and mac a backslash is a literal
# filename character, so the hardcoded separator produced a path that never
# resolved and broke the settings file bootstrap that every command depends on
$script:lib = Join-Path $PSModuleRoot 'lib'
$script:bin = Join-Path $PSModuleRoot 'bin'
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
# No classes currently ship; the ETS type data in Private/Register-FogTypeData.ps1
# is how FOG objects are modelled. See docs/plans/api-coverage-plan.md, "Typed objects".
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
Export-ModuleMember -Function $PublicFunctions.BaseName -Alias *
