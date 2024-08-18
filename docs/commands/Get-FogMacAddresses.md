---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogMacAddresses
schema: 2.0.0
---

# Get-FogMacAddresses

## SYNOPSIS
Gets all mac addresses in fog

## SYNTAX

```
Get-FogMacAddresses [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns all the objects in the macaddressassociations table which includes details on
the mac address, the hostID connected to, if it's a primary, and if it's a pending mac

## EXAMPLES

### EXAMPLE 1
```
$macs = Get-FogMacs
```

Gets all the mac addresses in fog and puts them in the $macs object

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
Has an alias of Get-FogMacs but made the main name be MacAddresses to avoid confusion with apple mac computers

## RELATED LINKS
