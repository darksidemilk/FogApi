---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Install-FogService
schema: 2.0.0
---

# Install-FogService

## SYNOPSIS
Attempts to install the fog service

## SYNTAX

```
Install-FogService [[-fogServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Attempts to download and install silently and then not so silently the fog service

## EXAMPLES

### EXAMPLE 1
```
Install-FogService
```

Will get the fogServer from the fogapi settings and use that servername to download the 
installers and then attempts first a silent install on the msi.
And attempts a interactive
install of the smart installer if that fails

## PARAMETERS

### -fogServer
the server to download from and connect to

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: ((Get-FogServerSettings).fogServer)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
