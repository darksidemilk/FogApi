---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogGroups
schema: 2.0.0
---

# Get-FogGroups

## SYNOPSIS
Returns all fog groups

## SYNTAX

```
Get-FogGroups [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets all the fog groups and returns them in an object

## EXAMPLES

### EXAMPLE 1
```
$groups = Get-FogGroups
```

## PARAMETERS

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
A group object does not contain membership information, you need to filter groupassociations to find membership
but this will give you the id of the group to search for within that object, you'll also need the host id to find all associations of a host

## RELATED LINKS
