---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogSetting
schema: 2.0.0
---

# Get-FogSetting

## SYNOPSIS
Get one fog setting by name or id

## SYNTAX

```
Get-FogSetting [[-settingName] <Object>] [[-settingID] <Object>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Gets the id, name, description, and value of a given fog setting by its ID or name
You can get all settings with Get-FogSettings

## EXAMPLES

### EXAMPLE 1
```
Get-FogSetting -settingName FOG_QUICKREG_PENDING_MAC_FILTER
```

Will return the value and info of FOG_QUICKREG_PENDING_MAC_FILTER

## PARAMETERS

### -settingName
The name of the setting

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -settingID
Alternatively use the ID of the setting to get the setting directly

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
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
General notes

## RELATED LINKS
