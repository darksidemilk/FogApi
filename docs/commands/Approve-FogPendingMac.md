---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Approve-FogPendingMac
schema: 2.0.0
---

# Approve-FogPendingMac

## SYNOPSIS
Approves a macaddress object

## SYNTAX

```
Approve-FogPendingMac [[-macObject] <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Approves a mac address object that was gotten from get-pendingMacsforHost
each of these objects has the properties from the macaddressassociation rest objects which are
id, hostID, mac, description, pending, primary, clientIgnore, and imageIgnore
This function simply changes Pending from 0 to 1 and then updates it via the api

## EXAMPLES

### EXAMPLE 1
```
$macToApprove = (Get-PendingMacsForHost -hostID 123)[0]
Approve-FogPendingMac -macObject $macToApprove
```

This gets the first mac to approve in the list of pending macs and approves it

### EXAMPLE 2
```
$pendingMac = (Get-PendingMacsForHost -hostID 123) | Where-object mac -eq "01:23:45:67:89"
Approve-FogPendingMac -macObject $pendingMac
```

Approve the specific pending mac address of "01:23:45:67:89" after finding it pending for a host of the id 123

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
