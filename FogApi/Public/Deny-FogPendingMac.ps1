function Deny-FogPendingMac {
<#
    .SYNOPSIS
    Deny a pending fog mac aka delete a fog mac address association entry
    
    .DESCRIPTION
    Deny the approval of a pending mac address to delete its entry from the mac address association rest objects
    
#>
    
    [CmdletBinding()]
    [Alias('Remove-FogMac')]
    param ( 
        $macObject
    )

    process {
        return Remove-FogObject -type object -coreObject macaddressassociation -IDofObject $macObject.id;
    }
    
}
