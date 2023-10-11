---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogSnapinAssociations
schema: 2.0.0
---

# Get-FogSnapinAssociations

## SYNOPSIS
Helper function that returns a list of all snapin associations to any host on the server

## SYNTAX

```
Get-FogSnapinAssociations [<CommonParameters>]
```

## DESCRIPTION
Returns a list from the snapinassociations table.
Each association has an id, hostid, and snapinid
Not to be confused with Get-FogHostAssociatedSnapins which filters this list to a single hostid and then gets the snapin object for each association

## EXAMPLES

### EXAMPLE 1
```
Get-FogSnapinAssociations
```

Will return a full list of all snapin ids associated to host ids

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
