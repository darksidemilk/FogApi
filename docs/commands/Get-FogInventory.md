---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogInventory
schema: 2.0.0
---

# Get-FogInventory

## SYNOPSIS
Gets a local computer's inventory with wmi and returns 
a json object that can be used to set fog inventory

## SYNTAX

```
Get-FogInventory [[-hostObj] <Object>] [-fromFog] [<CommonParameters>]
```

## DESCRIPTION
Uses various wmi classes to get every possible inventory item to set in fog

## EXAMPLES

### EXAMPLE 1
```
$json = Get-FogInventory; Set-FogInventory -jsonData $json
```

Gets the inventory of the currenthost using cim and formats in the proper json
then sets the inventory for that host in fog.

### EXAMPLE 2
```
Get-FogInventory -fromFog
```

Will return the inventory currently set on the fog host of the current computer
This will happen automatically if you run it from powershell core in linux as getting
the inventory of the linux machine isn't yet implemented

## PARAMETERS

### -hostObj
the host to get the model of the inventory object from
This is used for the inventory structure of the object
It defaults to the current host

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (Get-FogHost)
Accept pipeline input: False
Accept wildcard characters: False
```

### -fromFog
Switch param to simply return the currently set inventory of the fog host

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
