function Approve-FogPendingMac {
<#
    .SYNOPSIS
    Approves a macaddress object
    
    .DESCRIPTION
    Approves a mac address object that was gotten from get-pendingMacsforHost
    each of these objects has the properties from the macaddressassociation rest objects which are
    id, hostID, mac, description, pending, primary, clientIgnore, and imageIgnore
    This function simply changes Pending from 0 to 1 and then updates it via the api
#>
    
    [CmdletBinding()]
    param ( 
        [object]$macObject
    )

    process {
        $macObject.pending = 1;
        return Update-FogObject -type object -coreObject macaddressassociation -IDofObject $macObject.id -jsonData ($macObject | ConvertTo-Json)
    }
    
}
