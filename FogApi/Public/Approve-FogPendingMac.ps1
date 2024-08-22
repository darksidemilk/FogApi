function Approve-FogPendingMac {
<#
    .SYNOPSIS
    Approves a macaddress object
    
    .DESCRIPTION
    Approves a mac address object that was gotten from get-pendingMacsforHost
    each of these objects has the properties from the macaddressassociation rest objects which are
    id, hostID, mac, description, pending, primary, clientIgnore, and imageIgnore
    This function simply changes Pending from 0 to 1 and then updates it via the api

    .Parameter macobject
    Should be an item from the array return object from `Get-PendingMacsForHost`

    .EXAMPLE
    $macToApprove = (Get-PendingMacsForHost -hostID 123)[0]
    Approve-FogPendingMac -macObject $macToApprove

    This gets the first mac to approve in the list of pending macs and approves it
    
    .EXAMPLE
    $pendingMac = (Get-PendingMacsForHost -hostID 123) | Where-object mac -eq "01:23:45:67:89"
    Approve-FogPendingMac -macObject $pendingMac

    Approve the specific pending mac address of "01:23:45:67:89" after finding it pending for a host of the id 123

#>
    
    [CmdletBinding()]
    param ( 
        [parameter(ValueFromPipeline=$true)]
        [object]$macObject
    )

    process {
        if ($null -ne $_) {
            $macObject = $_;
        }
        $macObject.pending = '0';
        $data = ($macObject | ConvertTo-Json);
        $result = Update-FogObject -type object -coreObject macaddressassociation -IDofObject $macObject.id -jsonData $data 
        return $result;
    }
    
}
