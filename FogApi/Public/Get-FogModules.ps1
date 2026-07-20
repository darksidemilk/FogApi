function Get-FogModules {
    <#
    .SYNOPSIS
    Returns the modules in fog with their names, ids, descriptions, and if they're set to be enabled by default
    
    .DESCRIPTION
    Returns the api module object. Can be utilized to find what modules are enabled by default when creating a new host
    
    .EXAMPLE
    $mods = Get-FogModules; $mods

    Will put the list of modules in a variable and then display the list

    Expected output:
    [ { "id": 1, "name": "hostnameChanger" } ]

    .EXAMPLE
    Get-FogModules | Where-Object isDefault -eq '1'

    Will display the modules that are set to be enabled by default in your fog server settings

    Expected output:
    { "id": 1, "name": "hostnameChanger" }
    #>
    [CmdletBinding()]
    param ()
    
    process {
        $modules = (Get-FogObject -type object -coreObject module)
        return $modules.data;
    }
    
}