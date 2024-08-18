---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogSnapins
schema: 2.0.0
---

# Get-FogSnapins

## SYNOPSIS
Returns list of all snapins on fogserver

## SYNTAX

```
Get-FogSnapins [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gives a full list of all snapins on the fog server
uses get-fogobject to get the snapins then selects and expands the snapins property

## EXAMPLES

### EXAMPLE 1
```
Get-FogSnapins
```

Returns an array of objects with details of each snapin.

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

## RELATED LINKS
