---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Find-FogObject
schema: 2.0.0
---

# Find-FogObject

## SYNOPSIS
Searches for a fog object (of specified type, or searches all types \[fog 1.6 only\]) via the api
Note that it will search all fields for the search string, not just the name.

## SYNTAX

```
Find-FogObject [[-type] <String>] [[-stringToSearch] <String>] [<CommonParameters>]
```

## DESCRIPTION
Searches for a given string within a given coreobject type
Once a type has been selected the next parameter is dynamically added along with a tab completable list of options.
i.e type of object will add the coreobject parameter 
The stringToSearch you provide will be searched for in that object, just like if you were in the web gui searching for a host, group, etc. 
If you are using fog 1.6, you can set the $coreObject variable to 'unisearch' and it will do a universal search

## EXAMPLES

### EXAMPLE 1
```
Find-FogObject -type search -coreObject host -stringToSearch "computerName"
```

This will find and return all host objects that have 'computername' in any field.

### EXAMPLE 2
```
$result = Find-FogObject -type search -coreObject group -stringToSearch "IT"'; $result.data | Where-Object name -match "IT";
```

This will find all groups with IT in any field.
Then filter to where IT is in the name field and display that list

## PARAMETERS

### -type
Defaults to 'search' and can only be 'search', has to be set for the dynamic coreObject param to populate

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Search
Accept pipeline input: False
Accept wildcard characters: False
```

### -stringToSearch
The string to search for in the given object type or for universal search.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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
