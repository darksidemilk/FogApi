---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogObject
schema: 2.0.0
---

# Get-FogObject

## SYNOPSIS
Gets a fog object via the api

## SYNTAX

```
Get-FogObject [[-type] <String>] [[-jsonData] <Object>] [[-IDofObject] <String>] [<CommonParameters>]
```

## DESCRIPTION
Gets a object, objecactivetasktype, or performs a search via the api
Once a type has been selected the next parameter is dynamically added
along with a tab completable list of options.
i.e type of object will add the coreobject parameter

## EXAMPLES

### EXAMPLE 1
```
Get-FogObject -type object -coreObject host
```

This will get all hosts from the fog server.
This will get all the hosts.

## PARAMETERS

### -type
the type of object to get can be "objectactivetasktype","object", or "search"
Search is broken in the api in versions before 1.6 as I understand

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -jsonData
the json data in json string format if required

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IDofObject
the id of the object to get

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
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
