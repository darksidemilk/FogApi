---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Deny-FogPendingMac
schema: 2.0.0
---

# Deny-FogPendingMac

## SYNOPSIS
Deny a pending fog mac aka delete a fog mac address association entry

## SYNTAX

```
Deny-FogPendingMac [[-macObject] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Deny the approval of a pending mac address to delete its entry from the mac address association rest objects

## EXAMPLES

### EXAMPLE 1
```
$macToDeny = (Get-PendingMacsForHost -hostID 123)[0]
Deny-FogPendingMac -macObject $macToDeny
```

This gets the first mac to approve in the list of pending macs and approves it

### EXAMPLE 2
```
$pendingMac = (Get-PendingMacsForHost -hostID 123) | Where-object mac -eq "01:23:45:67:89"
Deny-FogPendingMac -macObject $pendingMac
```

Deny the specific pending mac of "01:23:45:67:89" after finding it pending for a host of the id 123

## PARAMETERS

### -macObject
Should be an item from the array return object from \`Get-PendingMacsForHost\`

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

## RELATED LINKS
