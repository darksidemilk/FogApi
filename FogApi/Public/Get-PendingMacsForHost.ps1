function Get-PendingMacsForHost {
    <#
    .SYNOPSIS
    Gets the pending macs for a given hosts
    
    .DESCRIPTION
    Gets the pending macs for a host that can then be approved with approve-fogpendingmac
    or denied with deny-fogpendingmac
    
    .PARAMETER hostID
    the hostid or hostname of the fog host
    
    .EXAMPLE
    Get-PendingMacsForhost -hostID 123

    gets the macs if any for foghost 123
    
    #>
    
    [CmdletBinding()]
    param (
        $hostID
    )
    
    
    process {
        if ($hostID.gettype().name -ne "Int32"){
            try {
                $hostID = Get-FogHost -hostname $hostID
            } catch {
                Write-Error "Please provide a valid hostid or hostname"
                exit;
            }
        }
        return Get-FogObject -type object -coreObject macaddressassociation | select-object -ExpandProperty macaddressassociations | Where-Object hostID -match $hostID | Where-Object pending -ne 0;
    }
    
}