---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-PendingMacsForHost
schema: 2.0.0
---

# Get-PendingMacsForHost

## SYNOPSIS
Gets the pending macs for a given hosts

## SYNTAX

```
Get-PendingMacsForHost [[-hostID] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Gets the pending macs for a host that can then be approved with approve-pendingmac

## EXAMPLES

### EXAMPLE 1
```
Get-PendingMacsForhost -hostID 123
```

gets the macs if any for foghost 123

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
