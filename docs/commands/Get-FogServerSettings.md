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
Get-FogServerSettings [<CommonParameters>]
```

## DESCRIPTION
Gets the current settings for use in api calls
If no settings exists creates and returns the default settings

## EXAMPLES

### EXAMPLE 1
```
Get-FogServerSettings
```

Converts the json settings file to a powershell object
and returns the api key and server name values

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
