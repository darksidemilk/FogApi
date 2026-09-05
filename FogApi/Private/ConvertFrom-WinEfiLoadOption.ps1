function ConvertFrom-WinEfiLoadOption {
<#
.SYNOPSIS
Parses the raw bytes of a uefi Boot#### variable into a usable object

.DESCRIPTION
Decodes an EFI_LOAD_OPTION:

    UINT32           Attributes
    UINT16           FilePathListLength
    CHAR16           Description[]      - null terminated
    EFI_DEVICE_PATH  FilePathList[]     - FilePathListLength bytes
    UINT8            OptionalData[]

and walks the device path nodes to decide whether the entry boots from the network,
which stack it uses, and which nic it belongs to.

Deciding by device path rather than by description is the whole point. "UEFI PXEv4",
"Network Boot", "EFI Network 0", "IBA GE Slot 0100 v1550" and "Onboard NIC (IPV4)"
are the same thing under different names, in whatever language the firmware shipped
in, and vendors keep inventing new ones. The bytes state the fact that the string
only hints at.

Returns null when the bytes are too short or malformed to be a load option. A
malformed entry is deliberately not reported as "not a network option", because
silently treating a truncated variable as "no pxe here" is how a machine that could
have netbooted gets reported as one that cannot.

.PARAMETER bytes
The raw value of a Boot#### firmware variable

.EXAMPLE
ConvertFrom-WinEfiLoadOption (Get-WinEfiVariable 'Boot0003')

Returns an object with Description, Active, Network, IPv4, IPv6 and MacAddress

.NOTES
Private helper for Get-WinNetBootOption.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [AllowNull()]
        [byte[]]$bytes
    )

    process {
        # A load option is at minimum the 6 byte header plus the description's
        # null terminator.
        if (($null -eq $bytes) -or ($bytes.Length -lt 8)) {
            Write-Verbose "Load option is $(if ($null -eq $bytes) {0} else {$bytes.Length}) bytes, too short for a header";
            return $null;
        }

        $attributes = [BitConverter]::ToUInt32($bytes, 0);
        $pathLength = [BitConverter]::ToUInt16($bytes, 4);

        # The description is utf-16le up to the first null unit. Walking in two
        # byte steps to the terminator is the only way to find where the device
        # path starts, the header does not say.
        $index = 6;
        $units = New-Object System.Collections.Generic.List[uint16];
        $terminated = $false;
        while (($index + 1) -lt $bytes.Length) {
            $unit = [BitConverter]::ToUInt16($bytes, $index);
            $index += 2;
            if ($unit -eq 0) { $terminated = $true; break; }
            $units.Add($unit);
        }
        if (-not $terminated) {
            Write-Verbose "Load option description is not null terminated, refusing to guess at it";
            return $null;
        }
        $description = -join ($units | ForEach-Object { [char]$_ });

        $pathEnd = $index + $pathLength;
        if ($pathEnd -gt $bytes.Length) {
            Write-Verbose "Load option device path claims $pathLength bytes but only $($bytes.Length - $index) are present";
            return $null;
        }

        # Walk the device path nodes. Each is UINT8 Type, UINT8 SubType,
        # UINT16 Length, where Length counts the 4 byte header too.
        # Messaging type 0x03 carries the nodes that mark a network boot: a MAC
        # node is present on every one of them, and the IPv4/IPv6 nodes say
        # which stack the entry would use.
        $isNetwork = $false;
        $isIPv4 = $false;
        $isIPv6 = $false;
        $mac = $null;
        $nodes = New-Object System.Collections.Generic.List[string];
        $cursor = $index;
        while (($cursor + 3) -lt $pathEnd) {
            $type = $bytes[$cursor];
            $subType = $bytes[$cursor + 1];
            $length = [BitConverter]::ToUInt16($bytes, $cursor + 2);
            # A node shorter than its own header, or longer than what is left,
            # means the path is corrupt. Stop rather than loop forever or read
            # off the end of the array.
            if (($length -lt 4) -or (($cursor + $length) -gt $pathEnd)) { break; }
            $nodes.Add(('{0:x2}/{1:x2}' -f $type, $subType));
            if ($type -eq 0x7f) { break; } # end of device path
            if ($type -eq 0x03) {
                switch ($subType) {
                    0x0b {
                        # MSG_MAC_ADDR_DP: EFI_MAC_ADDRESS is 32 bytes followed
                        # by a UINT8 IfType. Ethernet uses the first 6.
                        $isNetwork = $true;
                        if (($cursor + 10) -lt $pathEnd) {
                            $mac = (($bytes[($cursor + 4)..($cursor + 9)]) | ForEach-Object { $_.ToString('X2') }) -join '-';
                        }
                    }
                    0x0c { $isNetwork = $true; $isIPv4 = $true } # MSG_IPv4_DP
                    0x0d { $isNetwork = $true; $isIPv6 = $true } # MSG_IPv6_DP
                    0x18 { $isNetwork = $true } # MSG_URI_DP, http boot
                    0x1f { $isNetwork = $true; $isIPv4 = $true; $isIPv6 = $true } # MSG_DNS_DP
                }
            }
            $cursor += $length;
        }

        return [PSCustomObject]@{
            Description     = $description;
            Attributes      = $attributes;
            # LOAD_OPTION_ACTIVE. An entry without it is one the firmware will
            # not boot, so it is not a candidate however good its path looks.
            Active          = [bool]($attributes -band 0x00000001);
            Network         = $isNetwork;
            IPv4            = $isIPv4;
            IPv6            = $isIPv6;
            MacAddress      = $mac;
            DevicePathNodes = $nodes.ToArray();
        };
    }
}
