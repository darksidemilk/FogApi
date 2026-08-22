$PSModuleRoot = $PSScriptRoot
$script:lib = "$PSModuleRoot\lib"
$script:bin = "$PSModuleRoot\bin"
$PublicFunctions = @( Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue )
$PrivateFunctions = @( Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue )
# Classes must be dot-sourced FIRST -- a param() block that names a class as a
# type resolves it when the function is invoked, so anything in Public/Private
# referring to one has to be parsed after the class exists. invoke-modulebuild.ps1
# already concatenates Classes/ ahead of Public/ and Private/ for the built
# module; this keeps the source layout in the same order.
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
