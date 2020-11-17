function Get-PendingMacsForHost {
    <#
    .SYNOPSIS
    Gets the pending macs for a given hosts
    
    .DESCRIPTION
    Gets the macs for a host and filters them to just pending ones.
    The returned object can then be approved with approve-fogpendingmac
    or denied with deny-fogpendingmac
    
    .PARAMETER hostID
    the hostid or hostname of the fog host
    
    .EXAMPLE
    Get-PendingMacsForhost -hostID 123

    gets the macs if any for foghost 123

    .EXAMPLE
    Get-PendingMacsForhost -hostID 'ComputerName'
    
    Returns the pending macs for the host with the name ComputerName

    #>
    
    [CmdletBinding()]
    param (
        $hostID
    )
    
    
    process {
        if ($hostID.gettype().name -ne "Int32"){
            try {
                $hostID = (Get-FogHost -hostname $hostID).id
            } catch {
                Write-Error "Please provide a valid hostid or hostname"
                exit;
            }
        }

        $hostMacs = Get-MacsForHost -host ((Get-FogHost -hostID $hostID))
        $pendingMacs = $hostMacs | Where-Object pending -eq '1';
        return $pendingMacs;
    }
    
}