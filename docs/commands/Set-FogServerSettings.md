---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Set-FogServerSettings
schema: 2.0.0
---

# Set-FogServerSettings

## SYNOPSIS
Set fog server settings

## SYNTAX

### default (Default)
```
Set-FogServerSettings [-fogApiToken <String>] [-fogUserToken <String>] [-fogServer <String>]
 [<CommonParameters>]
```

### prompt
```
Set-FogServerSettings [-interactive] [<CommonParameters>]
```

## DESCRIPTION
Set the apitokens and server settings for api calls with this module
the settings are stored in a json file in the current users roaming appdata ($home/APPDATA/Roaming/FogApi)
In linux and mac machines The appdata/roaming folder will be created in the user's home folder
this is to keep it locked down and inaccessible to standard users
and keeps the settings from being overwritten when updating the module

## EXAMPLES

### EXAMPLE 1
```
Set-FogServerSettings -fogapiToken "12345abcdefg" -fogUserToken "abcdefg12345" -fogServer "fog"
```

This will set the current users FogApi/settings.json file to have the given api tokens and set it to use 
"fog" as the server name for the uri in all api calls.
These are of course example tokens and the actual tokens are much longer.

### EXAMPLE 2
```

```

## PARAMETERS

### -fogApiToken
fog API token is found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System

```yaml
Type: String
Parameter Sets: default
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -fogUserToken
your fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab

```yaml
Type: String
Parameter Sets: default
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -fogServer
your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer

```yaml
Type: String
Parameter Sets: default
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -interactive
switch to make setting these an interactive process

```yaml
Type: SwitchParameter
Parameter Sets: prompt
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
