---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogServerSettings
schema: 2.0.0
---

# Get-FogServerSettings

## SYNOPSIS
Gets the server settings set for this module

## SYNTAX

```
Get-FogServerSettings [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets the current settings for use in api calls
If no settings exists creates and returns the default settings which explain where to get each setting.
For getting the default file path for the server settings file, it uses get-fogserversettingsfile that will get the path based on the os and user
If the path doesn't exist it will be created and the security settings will be set by Set-FogServerSettingsFileSecurity

## EXAMPLES

### EXAMPLE 1
```
Get-FogServerSettings
```

Converts the json settings file to a powershell object
and returns the api key and server name values

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
