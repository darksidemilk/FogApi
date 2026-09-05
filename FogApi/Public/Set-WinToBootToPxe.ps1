function Set-WinToBootToPxe {
    <#
    .SYNOPSIS
    Find the pxe boot id and make it the first option in the machine's PERMANENT firmware boot order
    
    .DESCRIPTION
    Finds this machine's network boot entry and puts it first in the firmware boot order with
    `bcdedit /set {fwbootmgr} displayorder <id> /addfirst`.
    Only works in windows, requires admin rights

    This change is PERMANENT. `{fwbootmgr}`'s displayorder is the uefi BootOrder variable, so the
    machine boots to the network first on every boot from now on, not just the next one, until
    something puts the order back. It also deletes `{fwbootmgr}`'s bootsequence, which is the uefi
    BootNext variable, so any one shot boot already armed on this machine is cancelled.

    Both of those were measured with bcdedit against the raw firmware variables, they are not
    inferred from the names.

    If what you want is "boot to pxe once, for this FOG task, then go back to normal", use
    Set-WinBootNext instead. That arms BootNext, which the firmware consumes and deletes by
    itself, so a machine that never gets imaged is left exactly as it was.
    
    .EXAMPLE
    Set-WinToBootToPxe

    Will use Get-WinBcdPxeId to find the pxe id and then set that guid as the first boot option in your boot order, permanently
    
    .NOTES
    Will also remove any runonce or bootsequence entries that might stop the boot order change from
    taking place. On a uefi machine bootsequence IS the BootNext variable, so this cancels a pending
    one shot boot as a side effect.
    #>
    [CmdletBinding()]
    param (
        
    )
    
    process {
        if ($IsLinux -or $IsMacOS) {
            Write-Warning "This is currently only implemented for windows"
            return $null;
        } else {
            $pxeID = Get-WinBcdPxeId -notBootMgr;
            if ($Null -ne $pxeID) {
                $addFirst = "";
                $pxeID | Sort-Object -Descending | ForEach-Object {
                    $addFirst += (bcdedit /set "{fwbootmgr}" displayorder $_ /addfirst)
                }
                $fwboot = (bcdedit /enum "{fwbootmgr}")
                if ($fwboot -match "bootsequence") {
                    $removeRunOnce =  (bcdedit /deletevalue "{fwbootmgr}" bootsequence); #remove any run once boot options
                } else {
                    $removeRunOnce = "bootsequence value not present";
                }
                Write-Verbose "Remove Run Once options result: $removeRunOnce"
                return "Add first result: $addFirst`nRemove Run Once options result: $removeRunOnce"
            } else {
                Write-Warning "No pxe boot option was found! Nothing was done!"
                return $null;
            }
        }
        
    }
    
}