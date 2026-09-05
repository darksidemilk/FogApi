function Get-WinBootNext {
    <#
    .SYNOPSIS
    Returns the boot number currently armed in the uefi BootNext variable, or null if none is

    .DESCRIPTION
    Reads BootNext and returns the boot option number it names, ie 3 for Boot0003. Null means
    no one shot boot is pending, which is the normal state, and also the state right after the
    firmware has consumed one.

    Use it to confirm Set-WinBootNext actually stuck. Firmware that accepts a variable write and
    stores nothing is a real failure mode, so reading it back is the only honest way to say a
    machine is armed.

    .PARAMETER passThru
    Also return the matching boot entry from Get-WinNetBootOption, so you can see the
    description of what is armed rather than just its number.

    .EXAMPLE
    Get-WinBootNext

    Returns the armed boot number, or nothing when no one shot boot is pending

    .EXAMPLE
    Get-WinBootNext -passThru

    Returns the armed entry with its description and mac address

    .NOTES
    Windows only, and needs SeSystemEnvironmentPrivilege enabled, so an elevated prompt or the
    SYSTEM account.
    #>
    [CmdletBinding()]
    param (
        [switch]$passThru
    )

    process {
        if ($IsLinux -or $IsMacOS) {
            Write-Warning "This is currently only implemented for windows";
            return $null;
        }

        $raw = Get-WinEfiVariable -name 'BootNext';
        if ($null -eq $raw) {
            Write-Verbose "No BootNext is set, so no one shot boot is pending";
            return $null;
        }
        if ($raw.Length -lt 2) {
            Write-Warning "BootNext is $($raw.Length) bytes, which is not a uint16 boot number";
            return $null;
        }
        $number = [BitConverter]::ToUInt16($raw, 0);
        if ($passThru) {
            $match = Get-WinNetBootOption -all | Where-Object { $_.BootNumber -eq $number } | Select-Object -First 1;
            if ($null -ne $match) { return $match; }
            Write-Warning "BootNext names Boot$('{0:X4}' -f $number) but the firmware holds no such entry, that boot will fall through to the normal boot order";
        }
        return $number;
    }
}
