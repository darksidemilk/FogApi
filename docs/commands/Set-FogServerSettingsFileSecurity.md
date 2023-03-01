---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Set-FogServerSettingsFileSecurity
schema: 2.0.0
---

# Set-FogServerSettingsFileSecurity

## SYNOPSIS
Set the settings file or given file to full control for owner only, no access for anyone else

## SYNTAX

```
Set-FogServerSettingsFileSecurity [[-settingsFile] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Uses chmod 700 for linux and mac, uses powershell acl commands for windows users to set

## EXAMPLES

### EXAMPLE 1
```
An example
```

## PARAMETERS

### -settingsFile
The settings file, defaults to the default path for the settings file tiy

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (Get-FogServerSettingsFile)
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
