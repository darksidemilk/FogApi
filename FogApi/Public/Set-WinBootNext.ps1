function Set-WinBootNext {
    <#
    .SYNOPSIS
    Arms a one shot network boot by setting the uefi BootNext variable

    .DESCRIPTION
    Sets BootNext to a network boot entry, so the very next boot goes to pxe and every boot
    after that is unchanged. The firmware consumes and deletes BootNext as it uses it, so there
    is nothing to undo afterwards and nothing left behind if the machine is never imaged.

    This is the one to use before rebooting a machine into a FOG task. Set-WinToBootToPxe is the
    other half of the story and does something meaningfully different: it rewrites the permanent
    firmware boot order with `bcdedit /set {fwbootmgr} displayorder /addfirst`, which leaves the
    machine booting to the network first forever, and it deletes any pending BootNext on the way
    past. Prefer this cmdlet unless a permanent reorder is what you actually want.

    With no parameters it arms the entry Get-WinNetBootOption picks, which is found by device
    path rather than by searching descriptions for likely words.

    .PARAMETER bootOption
    A boot option from Get-WinNetBootOption. Accepts pipeline input.

    .PARAMETER bootNumber
    Arm this boot number directly, ie 3 for Boot0003. For the case where you know the entry and
    do not want it looked up.

    .PARAMETER macAddress
    Arm the network entry belonging to this nic, for a machine with more than one.

    .PARAMETER passThru
    Return the option that was armed instead of nothing.

    .EXAMPLE
    Set-WinBootNext

    Finds this machine's network boot entry and arms it for the next boot only

    .EXAMPLE
    Set-WinBootNext -macAddress 00-11-22-33-44-55 -passThru

    Arms the network entry belonging to that nic and returns it

    .EXAMPLE
    Get-WinNetBootOption | Select-Object -First 1 | Set-WinBootNext

    The same thing done explicitly, when you want to see what will be armed before arming it

    .NOTES
    Windows only, and needs SeSystemEnvironmentPrivilege enabled, so an elevated prompt or the
    SYSTEM account. Use Get-WinBootNext to confirm it stuck and Clear-WinBootNext to cancel it.
    #>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Medium',DefaultParameterSetName='find')]
    [Alias('Set-WinToNetBootOnce')]
    param (
        [Parameter(ParameterSetName='option',ValueFromPipeline=$true,Position=0)]
        [object]$bootOption,
        [Parameter(ParameterSetName='number')]
        [uint16]$bootNumber,
        [Parameter(ParameterSetName='find')]
        [string]$macAddress,
        [switch]$passThru
    )

    process {
        if ($IsLinux -or $IsMacOS) {
            Write-Warning "This is currently only implemented for windows";
            return $null;
        }

        $target = $null;
        switch ($PSCmdlet.ParameterSetName) {
            'option' {
                if ($null -eq $bootOption) {
                    Write-Warning "No boot option was passed in, nothing to arm";
                    return $null;
                }
                $target = $bootOption;
            }
            'number' {
                # Taken on trust: the caller named the entry, so do not second
                # guess it, but say what is being armed.
                $target = [PSCustomObject]@{
                    BootNumber  = $bootNumber;
                    BootVar     = 'Boot{0:X4}' -f $bootNumber;
                    Description = '(named by boot number)';
                };
            }
            default {
                $target = Get-WinNetBootOption -macAddress $macAddress | Select-Object -First 1;
                if ($null -eq $target) {
                    # Say which of the two failures this is. "No uefi here" and
                    # "uefi with pxe switched off" look identical from outside
                    # and need completely different fixes.
                    if ($null -eq (Get-WinEfiVariable -name 'BootOrder')) {
                        Write-Warning "No uefi boot manager to arm on this machine. On a bios/csm machine set the boot order in firmware setup instead, and check this session is elevated";
                    } else {
                        Write-Warning "This machine's firmware lists no network boot entry to arm. Enable pxe or network boot in firmware setup, then run Get-WinNetBootOption -all to see what it does list";
                    }
                    return $null;
                }
            }
        }

        if ($null -eq $target.BootNumber) {
            Write-Warning "The boot option given has no BootNumber, cannot arm it";
            return $null;
        }

        $label = "$($target.BootVar) '$($target.Description)'";
        if (-not $PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Arm $label as the next boot only (uefi BootNext)")) {
            return $null;
        }

        # BootNext is a single little endian uint16 naming a Boot#### option.
        $value = [BitConverter]::GetBytes([uint16]$target.BootNumber);
        if (-not (Set-WinEfiVariable -name 'BootNext' -value $value)) {
            Write-Warning "Could not arm $label";
            return $null;
        }

        # Never report a firmware write from our own bookkeeping. Firmware that
        # returns success and stores nothing is a real failure mode on vm and
        # oem firmware alike, so read it back before saying it worked.
        $readBack = Get-WinBootNext;
        if ($readBack -ne $target.BootNumber) {
            Write-Warning "BootNext was written but reads back as '$readBack' rather than $($target.BootNumber), this firmware did not keep it";
            return $null;
        }

        Write-Verbose "Armed $label for the next boot only";
        if ($passThru) { return $target; }
        return $null;
    }
}
