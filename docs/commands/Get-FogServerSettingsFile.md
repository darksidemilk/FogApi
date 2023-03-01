---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogServerSettingsFile
schema: 2.0.0
---

# Get-FogServerSettingsFile

## SYNOPSIS
Returns the path to the fog server settings file for the current user based on the OS

## SYNTAX

```
Get-FogServerSettingsFile [<CommonParameters>]
```

## DESCRIPTION
If this is windows then the current users roaming app data folder is used as a base path.
    A folder named FogApi will be created (on first call to get-fogserversettings or set-fogserversettings) and the api-settings.json will be in that folder
If this is linux or mac the $home variable is used as the base path
    A folder named .FogApi will be created (on first call to get-fogserversettings or set-fogserversettings) and the api-settings.json will be in that folder
This is meant mainly for internal use as a universal way to get this path without repeated code.
To get the settings configured use Get-FogServerSettings

## EXAMPLES

### EXAMPLE 1
```
Get-FogServerSettingsFile
```

Will return the path for the current user's settings file, 
i.e.
if your username was fog and you were on windows it would return C:\users\fog\AppData\Roaming\FogApi\api-settings.json
if your username was fog and you were on linux it wourld return /home/fog/.FogApi/api-settings.json

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
