function Get-FogSettings {
    <#
    .SYNOPSIS
    Get all fog settings
    
    .DESCRIPTION
    Returns all settings with their ids, names, values, and descriptions
    
    #>
    [CmdletBinding()]
    param (

    )
    
    process {
        if (Test-FogVerAbove1dot6) {
            return (Get-FogObject -type object -coreObject setting).data
        } else {
            Write-Warning "Getting fog config settings in the API is only available in FOG 1.6 and above!"
        } 
    }
    
}