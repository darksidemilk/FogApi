$PSModuleRoot = $PSScriptRoot
# Join-Path, not "$PSModuleRoot\lib" - on linux and mac a backslash is a literal
# filename character, so the hardcoded separator produced a path that never
# resolved and broke the settings file bootstrap that every command depends on
$script:lib = Join-Path $PSModuleRoot 'lib'
$script:bin = Join-Path $PSModuleRoot 'bin'
# Single posix test so a branch can't be written for linux and forget mac
$script:IsPosix = ($IsLinux -or $IsMacOS)
$PublicFunctions = @( Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue )
$PrivateFunctions = @( Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue )


foreach ($file in @($PublicFunctions + $PrivateFunctions)) {
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
Export-ModuleMember -Function $PublicFunctions.BaseName -Alias *
