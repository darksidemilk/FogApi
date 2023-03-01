---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogHostPendingMacs
schema: 2.0.0
---

# Get-FogHostPendingMacs

## SYNOPSIS
Gets the pending macs for a given hosts

## SYNTAX

```
Get-FogHostPendingMacs [[-hostID] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Gets the macs for a host and filters them to just pending ones.
The returned object can then be approved with approve-fogpendingmac
or denied with deny-fogpendingmac

## EXAMPLES

### EXAMPLE 1
```
Get-PendingMacsForhost -hostID 123
```

gets the macs if any for foghost 123

### EXAMPLE 2
```
Get-PendingMacsForhost -hostID 'ComputerName'
```

Returns the pending macs for the host with the name ComputerName

## PARAMETERS

### -hostID
the hostid or hostname of the fog host

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
