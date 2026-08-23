function Get-FogActiveTasks {
    <#
    .SYNOPSIS
    Gets the current active tasks
    
    .DESCRIPTION
    Gets the current active tasks and expands them into an object
    
    .EXAMPLE
    Get-FogActiveTasks

    This will list any active tasks and their properties

    Expected output:
    [ { "id": 1, "name": "ExampleTask" } ]

    #>
    
    [CmdletBinding()]
    param ()
    
    process {
        $result = Get-FogObject -type objectactivetasktype -coreActiveTaskObject task
        return (Add-FogTypeName -InputObject $result.data -TypeName 'FogApi.Task');
    }
}