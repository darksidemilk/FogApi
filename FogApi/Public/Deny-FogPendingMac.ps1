function Deny-FogPendingMac {
<#
    .SYNOPSIS
    Deny a pending fog mac aka delete a fog mac address association entry
    
    .DESCRIPTION
    Deny the approval of a pending mac address to delete its entry from the mac address association rest objects
    
    .Parameter macobject
    Should be an item from the array return object from `Get-PendingMacsForHost`

    .EXAMPLE
    $macToDeny = (Get-PendingMacsForHost -hostID 123)[0]
    Deny-FogPendingMac -macObject $macToDeny

    This gets the first mac to approve in the list of pending macs and approves it

    .EXAMPLE
    $pendingMac = (Get-PendingMacsForHost -hostID 123) | Where-object mac -eq "01:23:45:67:89"
    Deny-FogPendingMac -macObject $pendingMac

    Deny the specific pending mac of "01:23:45:67:89" after finding it pending for a host of the id 123    

#>
    
    [CmdletBinding()]
    [Alias('Remove-FogMac')]
    param ( 
        [Parameter(Mandatory=$true)]        
        $macObject
    )

    process {
        return Remove-FogObject -type object -coreObject macaddressassociation -IDofObject $macObject.id;
    }
    
}
