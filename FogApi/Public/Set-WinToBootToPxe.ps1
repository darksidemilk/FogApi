function Set-WinToBootToPxe {
    <#
    .SYNOPSIS
    Attempt to find the pxe boot id and set it as the first option in the fwbootmgr bcd boot order
    
    .DESCRIPTION
    Attempt to find the pxe boot id and set it as the first option in the fwbootmgr bcd boot order
    Only works in windows, requires admin rights
    
    .EXAMPLE
    Set-WinToBootToPxe

    Will use Get-WinBcdPxeId to search for the pxe id and then set that guid as the first boot option in your boot order
    
    .NOTES
    Will also remove any runonce or bootsequence entries that might stop the boot order change from taking place
    #>
    [CmdletBinding()]
    param (
        
    )
    
    process {
        if ($IsLinux -or $IsMacOS) {
            Write-Warning "This is currently only implemented for windows"
            return $null;
        } else {
            $pxeID = Get-WinBcdPxeId;
            if ($Null -ne $pxeID) {
                $addFirst = (bcdedit /set "{fwbootmgr}" displayorder $pxeID /addfirst)
                $fwboot = (bcdedit /enum "{fwbootmgr}")
                if ($fwboot -match "bootsequence") {
                    $removeRunOnce =  (bcdedit /deletevalue "{fwbootmgr}" bootsequence); #remove any run once boot options
                } else {
                    $removeRunOnce = "bootsequence value not present";
                }
                Write-Verbose "Remove Run Once options result: $removeRunOnce"
                return "Setting path result: $setPath`nAdd first result: $addFirst`nRemove Run Once options result: $removeRunOnce"
            } else {
                Write-Warning "No pxe boot option was found! Nothing was done!"
                return $null;
            }
        }
        
    }
    
}