---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogGroupByName
schema: 2.0.0
---

# Get-FogGroupByName

## SYNOPSIS
Gets a fog group object by name

## SYNTAX

```
Get-FogGroupByName [[-groupName] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Searches the group objects for one that has a matching name of the given name

## EXAMPLES

### EXAMPLE 1
```
$ITGroup = Get-FogGroupByName -groupName "IT"
```

Will return the group object with a name that matches "IT";

## PARAMETERS

### -groupName
The name of the group to search for

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Chose not to name this just get-foggroup as get-foggroup used to be a different function that got the group of a host
Made that an alias of Get-FogHostGroup to avoid breaking anyones code

## RELATED LINKS
