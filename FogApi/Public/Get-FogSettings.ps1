function Get-FogSettings {
    <#
    .SYNOPSIS
    Get all fog settings
    
    .DESCRIPTION
    Returns all settings with their ids, names, values, and descriptions

    .EXAMPLE
    $settings = Get-FogSettings; $settings

    Will put the list of settings in a variable and then display the list
    You can then use the $settings object to filter for specific settings and their values, or to find the id of a setting to use in Set-FogSetting
    
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