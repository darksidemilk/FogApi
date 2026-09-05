#
# Tests for the uefi network-boot cmdlets.
#
# Every load option below is REAL firmware output, captured rather than
# written by hand:
#   - the OVMF PXEv4 entry came out of a qemu/OVMF varstore that had actually
#     netbooted
#   - the VirtualBox entries were read off a VirtualBox 7.2 EFI guest
# That matters here more than usual. A hand-written fixture would share this
# parser's own assumptions about the layout, so it would go green whether or
# not the parser reads real firmware correctly.
#
# Accepts the same container Data as the other files under Tests/ (see
# Invoke-FogApiTests.ps1) even though it doesn't use them, so a shared
# New-PesterContainer -Data call doesn't fail parameter binding here.
param(
    [switch]$RealServer,
    [string[]]$Function,
    [string]$CoverageReportPath
)

BeforeAll {
    $moduleManifest = Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1'
    Import-Module $moduleManifest -Force

    function ConvertFrom-HexString([string]$hex) {
        return [byte[]]($hex -split '(?<=\G..)(?=.)' | ForEach-Object { [Convert]::ToByte($_, 16) })
    }

    # qemu/OVMF, "UEFI PXEv4 (MAC:525400123456)": MAC node then an IPv4 node.
    $script:ovmfPxeV4 = ConvertFrom-HexString '0100000056005500450046004900200050005800450076003400200028004d00410043003a003500320035003400300030003100320033003400350036002900000002010c00d041030a00000000010106000002030b2500525400123456000000000000000000000000000000000000000000000000000001030c1b0000000000000000000000000000000000000000000000007fff0400'

    # VirtualBox 7.2, "UEFI PXEv4 (MAC:080027E9FF13)": MAC node and no IP node
    # at all, which is the only shape that firmware keeps.
    $script:vboxPxeMacOnly = ConvertFrom-HexString '010000003b005500450046004900200050005800450076003400200028004d00410043003a003000380030003000320037004500390046004600310033002900000002010c00d041030a00000000010106000003030b2500080027e9ff130000000000000000000000000000000000000000000000000000017fff0400'

    # VirtualBox 7.2, "UEFI VBOX HARDDISK VBe93e54f9-1f6fcfec". This one is the
    # reason the parser matches on node SUBTYPE: it carries a messaging node
    # (type 0x03, subtype 0x12 = SATA), so anything that treats "has a
    # messaging node" as "is a network boot" calls the hard disk pxe.
    $script:vboxHardDisk = ConvertFrom-HexString '01000000200055004500460049002000560042004f005800200048004100520044004400490053004b00200056004200650039003300650035003400660039002d00310066003600660063006600650063002000000002010c00d041030a0000000001010600000d03120a000000ffff00007fff04004eac0881119f594d850ee21a522c59b2'

    # VirtualBox 7.2, "Windows Boot Manager" - a file path on the ESP.
    $script:vboxWinBootMgr = ConvertFrom-HexString '010000007400570069006e0064006f0077007300200042006f006f00740020004d0061006e006100670065007200000004012a000200000000680900000000000020030000000000861b49885b7ac44889ef84bd519d688e0202040446005c004500460049005c004d006900630072006f0073006f00660074005c0042006f006f0074005c0062006f006f0074006d006700660077002e00650066006900000031000100000010000000040000007fff0400'

    # VirtualBox 7.2, "UiApp" - the firmware setup app. Attributes 0x109, so
    # LOAD_OPTION_ACTIVE is set but it is not a boot device.
    $script:vboxUiApp = ConvertFrom-HexString '090100002c0055006900410070007000000004071400c9bdb87cebf8344faaea3ee4af6516a10406140021aa2c4614760345836e8ab6f46623317fff0400'

    # `bcdedit /enum firmware` from the same VirtualBox guest, verbatim,
    # trailing spaces on the descriptions included.
    $script:bcdFirmwareOutput = @(
        ''
        'Firmware Boot Manager'
        '---------------------'
        'identifier              {fwbootmgr}'
        'displayorder            {bootmgr}'
        '                        {8a8ff2c8-763b-11f1-86d8-806e6f6e6963}'
        'timeout                 0'
        ''
        'Windows Boot Manager'
        '--------------------'
        'identifier              {bootmgr}'
        'device                  partition=\Device\HarddiskVolume2'
        'description             Windows Boot Manager'
        ''
        'Firmware Application (101fffff)'
        '-------------------------------'
        'identifier              {8a8ff2c8-763b-11f1-86d8-806e6f6e6963}'
        'description             UEFI VBOX CD-ROM VB1-1a2b3c4d '
        ''
        'Firmware Application (101fffff)'
        '-------------------------------'
        'identifier              {b7c1e2f0-0000-4000-8000-0123456789ab}'
        'description             UEFI PXEv4 (MAC:525400123456)'
    )
}

Describe 'ConvertFrom-WinEfiLoadOption' {
    Context 'real network boot entries' {
        It 'reads an OVMF PXEv4 entry as an active IPv4 network boot with its mac' {
            InModuleScope FogApi -Parameters @{ bytes = $script:ovmfPxeV4 } {
                $option = ConvertFrom-WinEfiLoadOption -bytes $bytes
                $option.Description | Should -Be 'UEFI PXEv4 (MAC:525400123456)'
                $option.Active     | Should -BeTrue
                $option.Network    | Should -BeTrue
                $option.IPv4       | Should -BeTrue
                $option.MacAddress | Should -Be '52-54-00-12-34-56'
            }
        }

        It 'reads a VirtualBox mac-only entry as a network boot even with no IP node' {
            InModuleScope FogApi -Parameters @{ bytes = $script:vboxPxeMacOnly } {
                $option = ConvertFrom-WinEfiLoadOption -bytes $bytes
                $option.Network    | Should -BeTrue
                $option.IPv4       | Should -BeFalse
                $option.MacAddress | Should -Be '08-00-27-E9-FF-13'
            }
        }
    }

    Context 'real entries that are not network boots' {
        It 'does not call a SATA hard disk a network boot, despite its messaging node' {
            InModuleScope FogApi -Parameters @{ bytes = $script:vboxHardDisk } {
                $option = ConvertFrom-WinEfiLoadOption -bytes $bytes
                $option.Description | Should -BeLike 'UEFI VBOX HARDDISK*'
                $option.Network     | Should -BeFalse
                $option.MacAddress  | Should -BeNullOrEmpty
            }
        }

        It 'does not call the Windows Boot Manager a network boot' {
            InModuleScope FogApi -Parameters @{ bytes = $script:vboxWinBootMgr } {
                $option = ConvertFrom-WinEfiLoadOption -bytes $bytes
                $option.Description | Should -Be 'Windows Boot Manager'
                $option.Network     | Should -BeFalse
            }
        }

        It 'does not call the firmware setup app a network boot' {
            InModuleScope FogApi -Parameters @{ bytes = $script:vboxUiApp } {
                $option = ConvertFrom-WinEfiLoadOption -bytes $bytes
                $option.Description | Should -Be 'UiApp'
                $option.Network     | Should -BeFalse
            }
        }
    }

    Context 'malformed input' {
        # A truncated variable is not the same fact as "no pxe here", and
        # reporting it as one is how a machine that could netboot gets written
        # off as one that cannot. Null says "I could not read this".
        It 'returns null rather than a verdict for bytes too short to be a load option' {
            InModuleScope FogApi {
                ConvertFrom-WinEfiLoadOption -bytes ([byte[]](1, 0, 0, 0)) | Should -BeNullOrEmpty
            }
        }

        It 'returns null for a description with no null terminator' {
            InModuleScope FogApi {
                ConvertFrom-WinEfiLoadOption -bytes ([byte[]](1, 0, 0, 0, 4, 0, 0x41, 0, 0x42, 0)) | Should -BeNullOrEmpty
            }
        }

        It 'returns null when the device path claims more bytes than are present' {
            InModuleScope FogApi -Parameters @{ bytes = $script:ovmfPxeV4 } {
                $truncated = $bytes[0..($bytes.Length - 20)]
                ConvertFrom-WinEfiLoadOption -bytes $truncated | Should -BeNullOrEmpty
            }
        }
    }
}

Describe 'Get-WinBcdIdFromDescription' {
    It 'finds the bcd guid for a firmware description' {
        InModuleScope FogApi -Parameters @{ lines = $script:bcdFirmwareOutput } {
            Get-WinBcdIdFromDescription -description 'UEFI PXEv4 (MAC:525400123456)' -bcdOutput $lines |
                Should -Be '{b7c1e2f0-0000-4000-8000-0123456789ab}'
        }
    }

    It 'matches a description the firmware stored with a trailing space' {
        InModuleScope FogApi -Parameters @{ lines = $script:bcdFirmwareOutput } {
            Get-WinBcdIdFromDescription -description 'UEFI VBOX CD-ROM VB1-1a2b3c4d ' -bcdOutput $lines |
                Should -Be '{8a8ff2c8-763b-11f1-86d8-806e6f6e6963}'
        }
    }

    It 'returns null when nothing matches, rather than the nearest block' {
        InModuleScope FogApi -Parameters @{ lines = $script:bcdFirmwareOutput } {
            Get-WinBcdIdFromDescription -description 'EFI Network 0' -bcdOutput $lines |
                Should -BeNullOrEmpty
        }
    }
}

# These drive the whole cmdlet, which refuses to run off windows, so they are
# skipped elsewhere. The parsing above is where the fragile logic lives and it
# runs on every platform.
Describe 'Get-WinNetBootOption' -Skip:($IsLinux -or $IsMacOS) {
    It 'picks the network entry out of a real boot order and ignores the disk and setup app' {
        InModuleScope FogApi -Parameters @{
            pxe  = $script:ovmfPxeV4
            disk = $script:vboxHardDisk
            ui   = $script:vboxUiApp
        } {
            Mock Get-WinEfiVariable {
                switch ($name) {
                    'BootOrder' { return [byte[]](0x00, 0x00, 0x01, 0x00, 0x02, 0x00) }
                    'Boot0000'  { return $ui }
                    'Boot0001'  { return $disk }
                    'Boot0002'  { return $pxe }
                    default     { return $null }
                }
            }
            $found = @(Get-WinNetBootOption)
            $found.Count            | Should -Be 1
            $found[0].BootVar       | Should -Be 'Boot0002'
            $found[0].MacAddress    | Should -Be '52-54-00-12-34-56'
            $found[0].InBootOrder   | Should -BeTrue
        }
    }

    It 'prefers an IPv4 entry over an IPv6-only one that sits earlier in BootOrder' {
        InModuleScope FogApi -Parameters @{ pxe = $script:ovmfPxeV4 } {
            # Same real entry with the IPv4 node (03/0c) retyped as IPv6 (03/0d),
            # so the two differ only in the byte the choice turns on.
            $v6 = [byte[]]::new($pxe.Length)
            $pxe.CopyTo($v6, 0)
            $ipNode = [Array]::IndexOf($v6, [byte]0x0c, 100)
            $v6[$ipNode] = 0x0d
            Mock Get-WinEfiVariable {
                switch ($name) {
                    'BootOrder' { return [byte[]](0x05, 0x00, 0x06, 0x00) }
                    'Boot0005'  { return $v6 }
                    'Boot0006'  { return $pxe }
                    default     { return $null }
                }
            }
            $found = @(Get-WinNetBootOption)
            $found[0].BootVar | Should -Be 'Boot0006'
            $found[0].IPv4    | Should -BeTrue
        }
    }

    It 'finds a network entry the firmware holds but leaves out of BootOrder' {
        InModuleScope FogApi -Parameters @{ pxe = $script:ovmfPxeV4; disk = $script:vboxHardDisk } {
            Mock Get-WinEfiVariable {
                switch ($name) {
                    'BootOrder' { return [byte[]](0x01, 0x00) }
                    'Boot0001'  { return $disk }
                    'Boot0007'  { return $pxe }
                    default     { return $null }
                }
            }
            $found = @(Get-WinNetBootOption)
            $found.Count          | Should -Be 1
            $found[0].BootVar     | Should -Be 'Boot0007'
            $found[0].InBootOrder | Should -BeFalse
        }
    }

    It 'returns nothing when the firmware holds no network entry at all' {
        InModuleScope FogApi -Parameters @{ disk = $script:vboxHardDisk } {
            Mock Get-WinEfiVariable {
                switch ($name) {
                    'BootOrder' { return [byte[]](0x01, 0x00) }
                    'Boot0001'  { return $disk }
                    default     { return $null }
                }
            }
            Get-WinNetBootOption | Should -BeNullOrEmpty
        }
    }

    It 'filters to one nic by mac address' {
        InModuleScope FogApi -Parameters @{ pxe = $script:ovmfPxeV4; vbox = $script:vboxPxeMacOnly } {
            Mock Get-WinEfiVariable {
                switch ($name) {
                    'BootOrder' { return [byte[]](0x01, 0x00, 0x02, 0x00) }
                    'Boot0001'  { return $pxe }
                    'Boot0002'  { return $vbox }
                    default     { return $null }
                }
            }
            $found = @(Get-WinNetBootOption -macAddress '08:00:27:E9:FF:13')
            $found.Count       | Should -Be 1
            $found[0].BootVar  | Should -Be 'Boot0002'
        }
    }
}
