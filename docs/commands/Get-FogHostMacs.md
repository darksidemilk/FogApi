---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogHostMacs
schema: 2.0.0
---

# Get-FogHostMacs

## SYNOPSIS
Returns the macs assigned to a given host

## SYNTAX

```
Get-FogHostMacs [[-hostObject] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Gets all macs and finds the ones with a matching hostid of the given object
Use Get-FogHost to get the host object

## EXAMPLES

### EXAMPLE 1
```
Get-MacsForHost (Get-FogHost)
```

Will return the macs assigned to the computer running the command

## PARAMETERS

### -hostObject
The host object you get with Get-Foghost

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (Get-FogHost)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
