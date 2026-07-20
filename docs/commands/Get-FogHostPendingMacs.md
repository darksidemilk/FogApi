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

### byId (Default)
```
Get-FogHostPendingMacs [-hostID <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### byHost
```
Get-FogHostPendingMacs [-fogHost <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets the macs for a host and filters them to just pending ones.
The returned object can then be approved with approve-fogpendingmac
or denied with deny-fogpendingmac

## EXAMPLES

### EXAMPLE 1
```
Get-PendingMacsForhost -hostID 42
```

gets the macs if any for foghost 42

Expected output:
\[ { "mac": "01:23:45:67:89:99", "pending": "1" } \]

### EXAMPLE 2
```
Get-PendingMacsForhost -hostID 'MeowMachine'
```

Returns the pending macs for the host with the name MeowMachine

Expected output:
\[ { "mac": "01:23:45:67:89:99", "pending": "1" } \]

## PARAMETERS

### -fogHost
{{ Fill fogHost Description }}

```yaml
Type: Object
Parameter Sets: byHost
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -hostID
the hostid or hostname of the fog host

```yaml
Type: Object
Parameter Sets: byId
Aliases:

Required: False
Position: Named
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
