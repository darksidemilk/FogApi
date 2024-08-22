---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Set-WinToBootToPxe
schema: 2.0.0
---

# Set-WinToBootToPxe

## SYNOPSIS
Attempt to find the pxe boot id and set it as the first option in the fwbootmgr bcd boot order

## SYNTAX

```
Set-WinToBootToPxe [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Attempt to find the pxe boot id and set it as the first option in the fwbootmgr bcd boot order
Only works in windows, requires admin rights

## EXAMPLES

### EXAMPLE 1
```
Set-WinToBootToPxe
```

Will use Get-WinBcdPxeId to search for the pxe id and then set that guid as the first boot option in your boot order

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
Will also remove any runonce or bootsequence entries that might stop the boot order change from taking place

## RELATED LINKS
