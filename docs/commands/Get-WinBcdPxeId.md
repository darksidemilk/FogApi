---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-WinBcdPxeId
schema: 2.0.0
---

# Get-WinBcdPxeId

## SYNOPSIS
Searches bcd firmware options for a given or model specific search string and returns the boot device guid

## SYNTAX

```
Get-WinBcdPxeId [[-searchString] <String>] [-notBootMgr] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Returns the bcd object guid of this machine's network boot entry.
The id can be used with \`bcdedit /set "{fwbootmgr}" displayorder $pxeID /addfirst\` to be set as the first boot option in the computer's bios boot order

It asks the firmware first.
Get-WinNetBootOption identifies the network entry by its uefi
device path, which states what an entry is, and this then looks up the guid bcdedit knows
that same entry by, matching on the firmware's own description.
So the description is used
only to correlate two views of an entry already identified, never to work out what it is.

The description searching below it is the original behaviour, kept as the fallback for the
cases where the firmware variables cannot be read - an unelevated session, or a bios/csm
machine with no uefi boot manager at all - and used whenever an explicit -searchString is
given.
It looks for the up ethernet adapter's interface description, then 'IPV4', 'Network',
'LAN' and 'PXE' in turn, which works on most machines and quietly picks the wrong entry, or
none, on the ones that name things differently.

## EXAMPLES

### EXAMPLE 1
```
Get-WinBcdPxeId
```

Will return the guid of the native pxe boot option if one is found.

## PARAMETERS

### -searchString
Optionatlly specify a search string, can be pxe related or try to find a different id from \`bcdedit /enum firmware\`

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

### -notBootMgr
switch param to not return the main bootmgr entry if it is returned

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

## RELATED LINKS
