function Get-FogHosts {
<#
    .SYNOPSIS
    Gets all fog hosts
    
    .DESCRIPTION
    helper function for get-fogobject that gets all host objects
    The return object can be filtered with `Where-Object` to find hosts within based on host properties
    
    .EXAMPLE
    Get-FogHosts

    returns an array object with all hosts in the fogserver.
    
#>
    
    [CmdletBinding()]
    param ()
    
    begin {
        Write-Verbose "getting fog hosts"
    }
    
    process {
        $hosts = Get-FogObject -type Object -CoreObject host | Select-Object -ExpandProperty hosts
    }
    
    end {
        return $hosts;
    }

}
