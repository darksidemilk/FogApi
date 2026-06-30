---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogSettings
schema: 2.0.0
---

# Get-FogSettings

## SYNOPSIS
Get all fog settings

## SYNTAX

```
Get-FogSettings [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns all settings with their ids, names, values, and descriptions

## EXAMPLES

### EXAMPLE 1
```
$settings = Get-FogSettings; $settings
```

Will put the list of settings in a variable and then display the list
You can then use the $settings object to filter for specific settings and their values, or to find the id of a setting to use in Set-FogSetting

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
