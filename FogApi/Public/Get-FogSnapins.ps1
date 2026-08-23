function Get-FogSnapins {
<#
    .SYNOPSIS
    Returns list of all snapins on fogserver
    
    .DESCRIPTION
    Gives a full list of all snapins on the fog server
    uses get-fogobject to get the snapins then selects and expands the snapins property

    .EXAMPLE
    Get-FogSnapins

    Returns an array of objects with details of each snapin.

    Expected output:
    [ { "id": 5, "name": "office365" }, { "id": 6, "name": "chrome" } ]
#>
    
    [CmdletBinding()]
    param ()
    
    
    process {
        return (Add-FogTypeName -InputObject (Get-FogObject -type object -coreObject snapin).data -TypeName 'FogApi.Snapin');
    }
    
    
}