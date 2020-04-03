function Get-FogActiveTasks {
    <#
    .SYNOPSIS
    Gets the current active tasks
    
    .DESCRIPTION
    Gets the current active tasks and expands them into an object
    
    #>
    
    [CmdletBinding()]
    param ()
    
    process {
        return Get-FogObject -type objectactivetasktype -coreActiveTaskObject task | Select-Object -ExpandProperty tasks        
    }
}