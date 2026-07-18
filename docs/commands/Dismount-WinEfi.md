---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Dismount-WinEfi
schema: 2.0.0
---

# Dismount-WinEfi

## SYNOPSIS
Dismounts the EFI system partition if it is currently mounted

## SYNTAX

```
Dismount-WinEfi [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets the efi partition mount letter and dismounts it with the mountvol tool

## EXAMPLES

### EXAMPLE 1
```
Dismount-WinEfi
```

This example will dismount the efi partition if it is currently mounted

## PARAMETERS

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
