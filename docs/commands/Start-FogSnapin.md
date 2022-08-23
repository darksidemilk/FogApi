---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Start-FogSnapin
schema: 2.0.0
---

# Start-FogSnapin

## SYNOPSIS
Starts a single snapin task for a given machine

## SYNTAX

### byId (Default)
```
Start-FogSnapin [-hostID <Object>] [-snapinId <Object>] [<CommonParameters>]
```

### byName
```
Start-FogSnapin [-hostID <Object>] [-snapinname <Object>] [<CommonParameters>]
```

## DESCRIPTION
Requires the hostID of the fog host and then either the name of the snapin or the id of the snapin to deploy

## EXAMPLES

### EXAMPLE 1
```
Start-FogSnapin -hostID 1234 -snapinname 'office365'
```

This will find the id of the snapin named 'office365' and deploy it on the host o id 1234
The name of the host and the snapin will be output to the console before the task is started

### EXAMPLE 2
```
Start-FogSnapin -hostID 1234 -snapinid 12
```

This will deploy a single snapin task for the snapin of id 12 for host 1234
The name of the host and the snapin will be output to the console before the task is started

## PARAMETERS

### -hostID
The id of the host to deploy the task for

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

### -snapinname
The name of the snapin to deploy

```yaml
Type: Object
Parameter Sets: byName
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -snapinId
The id of the snapin to deploy

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
