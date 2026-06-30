---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Enable-FogApiHTTPS
schema: 2.0.0
---

# Enable-FogApiHTTPS

## SYNOPSIS
Enforce https in the url used in all api calls

## SYNTAX

```
Enable-FogApiHTTPS [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Prepends https to the fogserver property of fog server settings

## EXAMPLES

### EXAMPLE 1
```
Enable-FogApiHTTPS
```

This example will enforce https in the url used in all api calls by prepending https to the fogserver property of fog server settings

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
