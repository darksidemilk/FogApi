---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Set-FogSnapins
schema: 2.0.0
---

# Set-FogSnapins

## SYNOPSIS
Sets a list of snapins to a host, appends to existing ones

## SYNTAX

```
Set-FogSnapins [[-hostid] <Object>] [[-pkgList] <Object>] [-exactNames] [<CommonParameters>]
```

## DESCRIPTION
Goes through a provided list variable and adds each matching snapin to the provided hostid
Performs validation on the input before

## EXAMPLES

### EXAMPLE 1
```
Set-FogSnapins -hostid (Get-FogHost).id -pkgList @('Office365','chrome','slack')
```

This would associate snapins that match the titles of office365, chrome, and slack to the provided host id
they could then be deployed with start-fogsnapins

## PARAMETERS

### -hostid
The id of a host to set snapins on, defaults to finding if of current computer if none is given

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

### -pkgList
String array list of snapins to add to the host

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

### -exactNames
switch param to indicate matching to exact snapin names instead of matching the name.
Useful if you have things like office and office-64 that both match to 'office'

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
