$PSModuleRoot = $PSScriptRoot
$script:lib = "$PSModuleRoot\lib"
$script:bin = "$PSModuleRoot\bin"
$PublicFunctions = @( Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue )
$PrivateFunctions = @( Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue )
# Classes load first, and are loaded here only so the source layout matches what
# invoke-modulebuild.ps1 concatenates. Be aware of what this does NOT buy you:
# loading a class file from inside this .psm1 does not make the class resolvable
# by the functions dot-sourced below -- measured on pwsh 7.4.6, and the same
# either way, dot-source or Import-Module. A param() block naming a class
# resolves the type at INVOCATION, against the session's type table, and a class
# loaded in module scope never reaches it.
#
# What does work is importing the class files from the CALLER's scope after the
# module, which is what build.ps1:129-132 already does before running PlatyPS.
# Any class added here needs that same step wherever the module is consumed, or
# the cmdlet using it fails with "Unable to find type" at first call.
# No classes currently ship; the ETS type data in Private/Register-FogTypeData.ps1
# is how FOG objects are modelled. See CONTEXT-api-coverage-plan.md, "Typed objects".
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
