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

### byHostObject
```
Get-FogHostMacs [-hostObject <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### byHostID
```
Get-FogHostMacs [-hostID <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
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
Parameter Sets: byHostObject
Aliases:

Required: False
Position: Named
Default value: (Get-FogHost)
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -hostID
{{ Fill hostID Description }}

```yaml
Type: Object
Parameter Sets: byHostID
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
