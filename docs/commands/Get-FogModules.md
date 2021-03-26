---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogModules
schema: 2.0.0
---

# Get-FogModules

## SYNOPSIS
Returns the modules in fog with their names, ids, descriptions, and if they're set to be enabled by default

## SYNTAX

```
Get-FogModules [<CommonParameters>]
```

## DESCRIPTION
Returns the api module object.
Can be utilized to find what modules are enabled by default when creating a new host

## EXAMPLES

### EXAMPLE 1
```
$mods = Get-FogModules
$mods
```

Will put the list of modules in a variable and then display the list

### EXAMPLE 2
```
Get-FogModules | Where-Object isDefault -eq '1'
```

Will display the modules that are set to be enabled by default in your fog server settings

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
