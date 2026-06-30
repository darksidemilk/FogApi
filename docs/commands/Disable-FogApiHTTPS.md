---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Disable-FogApiHTTPS
schema: 2.0.0
---

# Disable-FogApiHTTPS

## SYNOPSIS
Enforce http in the url used in all api calls

## SYNTAX

```
Disable-FogApiHTTPS [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Prepends http to the fogserver property of fog server settings

## EXAMPLES

### EXAMPLE 1
```
Disable-FogApiHTTPS
```

This example will enforce http in the url used in all api calls by prepending http to the fogserver property of fog server settings

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

## RELATED LINKS
