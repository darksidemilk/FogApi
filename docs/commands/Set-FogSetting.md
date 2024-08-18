---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Set-FogSetting
schema: 2.0.0
---

# Set-FogSetting

## SYNOPSIS
Set a fog setting to a given value

## SYNTAX

### byname (Default)
```
Set-FogSetting [-settingName <Object>] [-value <Object>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### byId
```
Set-FogSetting [-settingID <Object>] [-value <Object>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### byObj
```
Set-FogSetting [-settingObj <Object>] [-value <Object>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Sets the value of a setting to the given value
No validation of the value is done, it is possible to pass an invalid value.
Most settings are ints or strings, some have special formatting or other requirements like being a file for the banner image
Updloading a file for a setting is not yet implemented.

## EXAMPLES

### EXAMPLE 1
```
$memLimit = Get-FogSetting -settingName FOG_MEMORY_LIMIT | Set-FogSetting -value 1024
```

Will get the setting object for FOG_MEMORY_LIMIT and set it to 1024 and return the new
value in the returned object in the $memLimit variable.

### EXAMPLE 2
```
Set-FogSetting -settingName FOG_WEB_HOST -value '192.168.0.1'
```

Would set the FOG_WEB_HOST to a new ip value and will return the resulting
object of that setting

## PARAMETERS

### -settingName
The name of the setting to set

```yaml
Type: Object
Parameter Sets: byname
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -settingID
The id of the setting to set

```yaml
Type: Object
Parameter Sets: byId
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -settingObj
Pipeline input supported.
The object should be the result of get-fogsetting

```yaml
Type: Object
Parameter Sets: byObj
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -value
Tha value to apply to the setting, ensure you're sending a valid value.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
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

## RELATED LINKS
