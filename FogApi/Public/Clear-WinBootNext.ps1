function Clear-WinBootNext {
    <#
    .SYNOPSIS
    Cancels a pending one shot network boot by deleting the uefi BootNext variable

    .DESCRIPTION
    Deletes BootNext, so the next boot follows the normal boot order again.

    Only needed when the reboot the arming was for is not going to happen. A BootNext left
    behind would send the machine to the network on whatever boot came next, for whatever
    reason, which is a surprise nobody wants. In the normal case the firmware deletes the
    variable itself as it consumes it and there is nothing to clean up.

    .EXAMPLE
    Clear-WinBootNext

    Cancels any pending one shot boot

    .NOTES
    Windows only, and needs SeSystemEnvironmentPrivilege enabled, so an elevated prompt or the
    SYSTEM account.
    #>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Low')]
    param ()

    process {
        if ($IsLinux -or $IsMacOS) {
            Write-Warning "This is currently only implemented for windows";
            return $false;
        }

        if ($null -eq (Get-WinEfiVariable -name 'BootNext')) {
            Write-Verbose "No BootNext was set, nothing to clear";
            return $true;
        }
        if (-not $PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Cancel the pending one shot boot (delete uefi BootNext)")) {
            return $false;
        }
        # A zero length write is how the win32 api expresses deleting a
        # firmware variable, there is no separate delete call.
        if (-not (Set-WinEfiVariable -name 'BootNext' -value @())) {
            Write-Warning "Could not clear BootNext";
            return $false;
        }
        return $true;
    }
}
