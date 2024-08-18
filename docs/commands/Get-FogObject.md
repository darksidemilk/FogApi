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
Get-FogObject [[-type] <String>] [[-jsonData] <Object>] [[-IDofObject] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets a object, objecactivetasktype, or performs a search via the api
Once a type has been selected the next parameter is dynamically added
along with a tab completable list of options.
i.e type of object will add the coreobject parameter 
Note that getting a fog object is similar but different from searching aka finding a fog object.
Use Find-FogObject for searching

## EXAMPLES

### EXAMPLE 1
```
Get-FogObject -type object -coreObject host
```

This will get all hosts from the fog server.
This will get all the hosts.

## PARAMETERS

### -type
the type of object to get can be "objectactivetasktype" or "object", object is for most items, the other is for getting active tasks

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
the specific id of the object to get

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
