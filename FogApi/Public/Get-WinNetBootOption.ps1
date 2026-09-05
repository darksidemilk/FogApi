function Get-WinNetBootOption {
    <#
    .SYNOPSIS
    Returns the uefi boot entries that boot from the network, found by device path rather than by description

    .DESCRIPTION
    Reads the firmware's own BootOrder and Boot#### variables and returns the entries whose
    device path contains a network node, most preferred first.

    This is the accurate answer to "which boot option is pxe on this machine". Get-WinBcdPxeId
    searches the text of `bcdedit /enum firmware` for likely looking words, which works on most
    machines and quietly picks the wrong entry, or none, on the ones that name things
    differently. Firmware calls a network entry "UEFI PXEv4", "Network Boot", "EFI Network 0",
    "Onboard NIC (IPV4)" or "IBA GE Slot 0100 v1550" depending on the vendor, the model and the
    language it shipped in. The device path says what the entry actually is, in bytes, and that
    is what this reads.

    Ordering follows the firmware's own BootOrder, with one adjustment: an IPv4 entry is
    preferred over an IPv6 only one, because FOG serves pxe over IPv4 and a machine sent to an
    IPv6 entry goes looking for a server that is not there.

    Entries not listed in BootOrder are included after the ordered ones, because firmware is
    free to hold an option it does not currently offer, and that is exactly the sort of entry an
    admin is hunting for when pxe "is not there".

    Returns nothing when the firmware holds no network entry. That is a real answer, and a
    different one from "this machine has no uefi" - it usually means pxe or network boot is
    turned off in firmware setup.

    .PARAMETER macAddress
    Only return entries belonging to this nic, matched against the MAC in the device path.
    Accepts 001122334455, 00-11-22-33-44-55 or 00:11:22:33:44:55.

    .PARAMETER includeInactive
    Also return entries the firmware has marked inactive. They will not boot as they stand, so
    they are excluded by default, but seeing one is the answer to "why can this machine not pxe".

    .PARAMETER all
    Return every boot entry rather than only the network ones, each with its Network, IPv4 and
    MacAddress properties filled in. Meant for working out why a machine's pxe entry was not
    found.

    .EXAMPLE
    Get-WinNetBootOption

    Returns the network boot entries this machine holds, best first

    .EXAMPLE
    (Get-WinNetBootOption)[0] | Set-WinBootNext

    Arms the best network boot entry for the next boot only

    .EXAMPLE
    Get-WinNetBootOption -all | Format-Table BootVar,Description,Network,IPv4,MacAddress

    Shows every firmware boot entry and what this module makes of it, which is the first thing
    to run when a machine will not pxe

    .NOTES
    Windows only, and reading firmware variables needs SeSystemEnvironmentPrivilege enabled,
    which means an elevated prompt or the SYSTEM account. Run from an admin powershell.
    #>
    [CmdletBinding()]
    [Alias('Get-WinPxeBootOption')]
    param (
        [string]$macAddress,
        [switch]$includeInactive,
        [switch]$all
    )

    process {
        if ($IsLinux -or $IsMacOS) {
            Write-Warning "This is currently only implemented for windows";
            return $null;
        }

        $order = Get-WinEfiVariable -name 'BootOrder';
        if ($null -eq $order) {
            Write-Verbose "Could not read BootOrder. Either there is no uefi boot manager here (a bios/csm machine) or this session lacks SeSystemEnvironmentPrivilege";
            return $null;
        }
        if (($order.Length % 2) -ne 0) {
            Write-Warning "BootOrder is $($order.Length) bytes, which is not a list of uint16 boot numbers";
            return $null;
        }

        $ordered = New-Object System.Collections.Generic.List[uint16];
        for ($i = 0; ($i + 1) -lt $order.Length; $i += 2) {
            $ordered.Add([BitConverter]::ToUInt16($order, $i));
        }

        # Walk BootOrder first so the firmware's own preference is kept, then
        # sweep 0000-00FF for entries it holds but does not currently offer.
        $numbers = New-Object System.Collections.Generic.List[uint16];
        $ordered | ForEach-Object { if (-not $numbers.Contains($_)) { $numbers.Add($_) } }
        0..255 | ForEach-Object { if (-not $numbers.Contains([uint16]$_)) { $numbers.Add([uint16]$_) } }

        $wantedMac = $null;
        if (Test-StringNotNullOrEmpty $macAddress) {
            $wantedMac = ($macAddress -replace '[^0-9A-Fa-f]', '').ToUpper();
            if ($wantedMac.Length -ne 12) {
                Write-Warning "macAddress '$macAddress' is not 6 hex octets, ignoring it";
                $wantedMac = $null;
            }
        }

        $found = New-Object System.Collections.Generic.List[object];
        foreach ($number in $numbers) {
            $bootVar = 'Boot{0:X4}' -f $number;
            $raw = Get-WinEfiVariable -name $bootVar;
            if ($null -eq $raw) { continue; }
            $option = ConvertFrom-WinEfiLoadOption -bytes $raw;
            # A malformed entry is skipped rather than treated as "not network":
            # ConvertFrom-WinEfiLoadOption has already said why on the verbose stream.
            if ($null -eq $option) { continue; }

            if ((-not $all) -and (-not $option.Network)) { continue; }
            if ((-not $all) -and (-not $includeInactive) -and (-not $option.Active)) {
                Write-Verbose "$bootVar '$($option.Description)' is a network entry but is marked inactive, use -includeInactive to see it";
                continue;
            }
            if (($null -ne $wantedMac) -and ($option.MacAddress -replace '[^0-9A-Fa-f]', '') -ne $wantedMac) { continue; }

            $position = $ordered.IndexOf($number);
            $found.Add([PSCustomObject]@{
                BootNumber      = $number;
                BootVar         = $bootVar;
                Description     = $option.Description;
                Network         = $option.Network;
                IPv4            = $option.IPv4;
                IPv6            = $option.IPv6;
                MacAddress      = $option.MacAddress;
                Active          = $option.Active;
                InBootOrder     = ($position -ge 0);
                BootOrderIndex  = $(if ($position -ge 0) { $position } else { [int]::MaxValue });
                DevicePathNodes = $option.DevicePathNodes;
            });
        }

        if ($found.Count -eq 0) {
            Write-Verbose "The firmware lists no network boot entry. On most machines that means pxe or network boot is disabled in firmware setup";
            return $null;
        }

        # BootOrder position first, then IPv4 ahead of IPv6 only, then the
        # boot number so the order is stable between runs.
        return ($found | Sort-Object @{Expression = 'BootOrderIndex'}, @{Expression = {-not $_.IPv4}}, @{Expression = 'BootNumber'});
    }
}
