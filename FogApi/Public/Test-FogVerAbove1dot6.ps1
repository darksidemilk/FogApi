function Test-FogVerAbove1dot6 {
    <#
    .SYNOPSIS
    Tests if the fog version is above 1.6 where api changes have occurred
    
    .DESCRIPTION
    Tests if the version string matches 1.5 string, if it doesn't then it's likely above 1.6
    
    .NOTES
    Could also make this a script scoped variable, but getting the version requires at least the fog server name
    which has to be set in intial setup and would throw errors on first install.
    #>
    [CmdletBinding()]
    param (
        
    )
    
    process {
        if ((Get-FogVersion -wa 0 -ea 0 -nowarning) -notlike "1.5*") {
            return $true;
        } else {
            return $false;
        }
    }
    
}