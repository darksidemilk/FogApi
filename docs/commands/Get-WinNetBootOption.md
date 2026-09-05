---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-WinNetBootOption
schema: 2.0.0
---

# Get-WinNetBootOption

## SYNOPSIS
Returns the uefi boot entries that boot from the network, found by device path rather than by description

## SYNTAX

```
Get-WinNetBootOption [[-macAddress] <String>] [-includeInactive] [-all] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Reads the firmware's own BootOrder and Boot#### variables and returns the entries whose
device path contains a network node, most preferred first.

This is the accurate answer to "which boot option is pxe on this machine".
Get-WinBcdPxeId
searches the text of \`bcdedit /enum firmware\` for likely looking words, which works on most
machines and quietly picks the wrong entry, or none, on the ones that name things
differently.
Firmware calls a network entry "UEFI PXEv4", "Network Boot", "EFI Network 0",
"Onboard NIC (IPV4)" or "IBA GE Slot 0100 v1550" depending on the vendor, the model and the
language it shipped in.
The device path says what the entry actually is, in bytes, and that
is what this reads.

Ordering follows the firmware's own BootOrder, with one adjustment: an IPv4 entry is
preferred over an IPv6 only one, because FOG serves pxe over IPv4 and a machine sent to an
IPv6 entry goes looking for a server that is not there.

Entries not listed in BootOrder are included after the ordered ones, because firmware is
free to hold an option it does not currently offer, and that is exactly the sort of entry an
admin is hunting for when pxe "is not there".

Returns nothing when the firmware holds no network entry.
That is a real answer, and a
different one from "this machine has no uefi" - it usually means pxe or network boot is
turned off in firmware setup.

## EXAMPLES

### EXAMPLE 1
```
Get-WinNetBootOption
```

Returns the network boot entries this machine holds, best first

### EXAMPLE 2
```
(Get-WinNetBootOption)[0] | Set-WinBootNext
```

Arms the best network boot entry for the next boot only

### EXAMPLE 3
```
Get-WinNetBootOption -all | Format-Table BootVar,Description,Network,IPv4,MacAddress
```

Shows every firmware boot entry and what this module makes of it, which is the first thing
to run when a machine will not pxe

## PARAMETERS

### -macAddress
Only return entries belonging to this nic, matched against the MAC in the device path.
Accepts 001122334455, 00-11-22-33-44-55 or 00:11:22:33:44:55.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -includeInactive
Also return entries the firmware has marked inactive.
They will not boot as they stand, so
they are excluded by default, but seeing one is the answer to "why can this machine not pxe".

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -all
Return every boot entry rather than only the network ones, each with its Network, IPv4 and
MacAddress properties filled in.
Meant for working out why a machine's pxe entry was not
found.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Windows only, and reading firmware variables needs SeSystemEnvironmentPrivilege enabled,
which means an elevated prompt or the SYSTEM account.
Run from an admin powershell.

## RELATED LINKS
