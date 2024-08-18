---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Test-FogVerAbove1dot6
schema: 2.0.0
---

# Test-FogVerAbove1dot6

## SYNOPSIS
Tests if the fog version is above 1.6 where api changes have occurred

## SYNTAX

```
Test-FogVerAbove1dot6 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Tests if the version string matches 1.5 string, if it doesn't then it's likely above 1.6

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

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
Could also make this a script scoped variable, but getting the version requires at least the fog server name
which has to be set in intial setup and would throw errors on first install.

## RELATED LINKS
