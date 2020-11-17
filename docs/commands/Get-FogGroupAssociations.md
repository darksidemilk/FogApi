---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogGroupAssociations
schema: 2.0.0
---

# Get-FogGroupAssociations

## SYNOPSIS
Gets the group association objects that can be used to find group memberships

## SYNTAX

```
Get-FogGroupAssociations [<CommonParameters>]
```

## DESCRIPTION
Returns the objects in the groupassociations table

## EXAMPLES

### EXAMPLE 1
```
$groupAssocs = Get-FogGroupAssociations;
$groupAssocs | ? hostId -eq ((Get-FogHost).id)
```

Would give you the group associations of the current computer

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
