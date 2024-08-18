---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Repair-FogSnapinAssociations
schema: 2.0.0
---

# Repair-FogSnapinAssociations

## SYNOPSIS
Finds any invalid snapin associations and removes them from the server

## SYNTAX

```
Repair-FogSnapinAssociations [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Finds any snapin associations that have a snapinID or hostID of 0 or a negative number or that have a snapin or host id that doesn't exist in the server
Displays the ones that will be deleted if any are found and then removes them. 
You can use -debug to pause and display each association before it is deleted (assuming your $debugpreference variable is set to 'inquire')

## EXAMPLES

### EXAMPLE 1
```
Repair-FogSnapinAssociations
```

'Example of output when there are associations to remove'
These snapin assoiciations have an invalid snapinID either of 0 or -1 or an id that doesn't belong to any snapins in the server and will be removed:

id    hostID snapinID
--    ------ --------
9289  1809   0
9985  1866   0
10000 2091   0

These snapin assoiciations have an invalid hostID of either 0 or -1 or other negative number, or have a hostid that doesn't belong to any host and will be removed:

id   hostID snapinID
--   ------ --------
8281 1787   103
8513 1960   103
8597 1935   635
8598 1935   629
8599 1933   639
8600 1935   69
8601 1935   137
9353 0      681
9354 0      684

Snapin Association repair complete!

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
When running Get-FogHostAssociatedSnapins, if associations with invalid snapin ids are found,

## RELATED LINKS
