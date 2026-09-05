---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-WinBootNext
schema: 2.0.0
---

# Get-WinBootNext

## SYNOPSIS
Returns the boot number currently armed in the uefi BootNext variable, or null if none is

## SYNTAX

```
Get-WinBootNext [-passThru] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Reads BootNext and returns the boot option number it names, ie 3 for Boot0003.
Null means
no one shot boot is pending, which is the normal state, and also the state right after the
firmware has consumed one.

Use it to confirm Set-WinBootNext actually stuck.
Firmware that accepts a variable write and
stores nothing is a real failure mode, so reading it back is the only honest way to say a
machine is armed.

## EXAMPLES

### EXAMPLE 1
```
Get-WinBootNext
```

Returns the armed boot number, or nothing when no one shot boot is pending

### EXAMPLE 2
```
Get-WinBootNext -passThru
```

Returns the armed entry with its description and mac address

## PARAMETERS

### -passThru
Also return the matching boot entry from Get-WinNetBootOption, so you can see the
description of what is armed rather than just its number.

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
Windows only, and needs SeSystemEnvironmentPrivilege enabled, so an elevated prompt or the
SYSTEM account.

## RELATED LINKS
