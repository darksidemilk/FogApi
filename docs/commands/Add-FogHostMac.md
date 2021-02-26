---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Add-FogHostMac
schema: 2.0.0
---

# Add-FogHostMac

## SYNOPSIS
Adds a given macaddress to a host of a given ID

## SYNTAX

```
Add-FogHostMac [[-hostID] <Object>] [[-macAddress] <Object>] [-primary] [-ignoreMacOnClient]
 [-ignoreMacForImaging] [<CommonParameters>]
```

## DESCRIPTION
Adds a given macaddress to a host of a given ID, optionatlly it can be set as primary

## EXAMPLES

### EXAMPLE 1
```
Add-FogHostMac -hostid 123 -macaddress "12:34:56:78:90" -primary
```

Add the macaddress "12:34:56:78:90" of the host with the id 123 and set it as the primary mac

### EXAMPLE 2
```
Add-FogHostMac -hostID "computerName" -macaddress "12:34:56:78:90"
```

Uses the hostname to find the hostid in fog then adds "12:34:56:78:90" as a secondary mac on the host

## PARAMETERS

### -hostID
Can either be the id number of the host object or the name of the host in a string

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

### -macAddress
The mac address you want to add.
Should be in the format of "12:34:56:78:90"

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -primary
switch parameter to set the macaddress as the primary for the host

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ignoreMacOnClient
set this switch param if you need this mac to be ignored by the fog client

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ignoreMacForImaging
Set this switch param if you need this mac to be ignored by the pxe client

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
