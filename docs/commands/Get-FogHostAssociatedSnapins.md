---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogHostAssociatedSnapins
schema: 2.0.0
---

# Get-FogHostAssociatedSnapins

## SYNOPSIS
Returns list of all snapins associated with a given hostid, defaults to current host if no hostid is given

## SYNTAX

```
Get-FogHostAssociatedSnapins [[-hostId] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Gives a full list of all snapins associated with a given host
Gets the current host's associated snapins if no hostid is given
Finds the associated snapins by first getting all snapinassociations with all hosts and filters to ones with the hostid
It then uses the snapinid of that filtering to get and add each snapin object to a list object
If it finds a snapin association with a snapinID of '0' that one will be skipped in the return and a warning will be displayed telling you to run Repair-FogSnapinAssociations

## EXAMPLES

### EXAMPLE 1
```
$assignedSnapins = Get-FogAssociatedSnapins; $assignedSnapins | Where-Object name -match "office"
```

Gets all the assigned snapins of the current host and then filters to any with the name office in them
thus showing you what version of office you have assigned as a snapin to your host

## PARAMETERS

### -hostId
The id of the host you want the assigned snapins to
Defaults to getting the current hosts id with ((Get-FogHost).id)

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: ((Get-FogHost).id)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
