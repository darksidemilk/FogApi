---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogLog
schema: 2.0.0
---

# Get-FogLog

## SYNOPSIS
Get a auto updating fog log

## SYNTAX

```
Get-FogLog [-static] [<CommonParameters>]
```

## DESCRIPTION
For Windows
Uses get-content -wait to show a dynamic fog log or use -static to just see the current contents

## EXAMPLES

### EXAMPLE 1
```
Get-FogLog
```

Will open a live display of the fog log as it is written to

### EXAMPLE 2
```
Get-FogLog -static
```

Will return the contents of the fog log as a string

## PARAMETERS

### -static
show the static contents of the fog log

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
