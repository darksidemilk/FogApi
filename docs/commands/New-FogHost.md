---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/New-FogHost
schema: 2.0.0
---

# New-FogHost

## SYNOPSIS
Creates a new host in fog

## SYNTAX

### default (Default)
```
New-FogHost -name <String> -macs <String[]> [-modules <String[]>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### custom
```
New-FogHost -customHost <Object> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Has 2 parameter sets,
a default set that lets you create a simple host with a name, mac addr or list of macs,  and either specified fog service/client modules or the ones you have configured as default on your fog server. 
And a custom mode that lets you pass a custom host object that you'll need to validate yourself, but you can then add snapins, groups, etc in the host creation object.
This is an advanced method and no validation is currently provided
When using the default set of params some validation is performed, the name is checked for whitespace, if there is whitespace it is replaced with a '-' unless it's at the end of the string
It will also check if any hosts already exist with the given name or the given mac addresses, if one does exist the existing host is returned.
If a new host is created, that host object is returned

## EXAMPLES

### EXAMPLE 1
```
New-FogHost -name "test-host" -macs "01:23:45:67:89:00"
```

Will create a new host in fog with the name "test-host"

## PARAMETERS

### -name
The hostname of the new fog host, should not have spaces or special characters other than '-' or '_'
Should follow general hostname rules.
Only whitespace is currently checked.
If you input an invalid hostname it may create the host but you won't be able to view the host in fog

```yaml
Type: String
Parameter Sets: default
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -macs
A single or list of mac addresses for the host.
The first mac in the list will be the primary.
Mac's should be in the format "00:01:23:45:67:89" additional macs can be added as a comma separated list to create a string array

```yaml
Type: String[]
Parameter Sets: default
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -modules
The ids of the modules to enable on the host. 
Defaults to getting the modules you have set to be enabled on the fog server
You can view your existing modules and create a custom list by utilizing Get-FogModules

```yaml
Type: String[]
Parameter Sets: default
Aliases:

Required: False
Position: Named
Default value: ((Get-FogModules | Where-Object isDefault -eq '1') | Select-Object -ExpandProperty id)
Accept pipeline input: False
Accept wildcard characters: False
```

### -customHost
Optionally specify a full host object to create a host object with additional params such as snapinIds and groupids,
this parameter has less testing done on it but is provided for flexibility until more default parameters are added.
A customHost object should at least have the properties name and macs and can have additional ones as well.
It can be created like this 
$customHost = @{
    name = "name";
    macs = "00:01:23:45:67:89";
    modules = ((Get-FogModules | Where-Object isDefault -eq '1') | Select-Object -ExpandProperty id);
}
Refer to the fog api documentaiton and the forums for information on additional properties to add

```yaml
Type: Object
Parameter Sets: custom
Aliases:

Required: True
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
