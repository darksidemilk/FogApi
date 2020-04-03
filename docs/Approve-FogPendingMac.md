---
external help file: fogapi-help.xml
Module Name: fogapi
online version:
schema: 2.0.0
---

# Approve-FogPendingMac

## SYNOPSIS
Approves a macaddress object

## SYNTAX

```
Approve-FogPendingMac [[-macObject] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Approves a mac address object that was gotten from get-pendingMacsforHost
each of these objects has the properties from the macaddressassociation rest objects which are
id, hostID, mac, description, pending, primary, clientIgnore, and imageIgnore
This function simply changes Pending from 0 to 1 and then updates it via the api

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -macObject
{{ Fill macObject Description }}

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
