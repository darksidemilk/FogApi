---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-WinEfiMountLetter
schema: 2.0.0
---

# Get-WinEfiMountLetter

## SYNOPSIS
If the EFI partition is mounted this returns the current drive letter

## SYNTAX

```
Get-WinEfiMountLetter [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Runs the mountvol.exe tool and parses out the string at the end of the output
that states if and where the EFI system partition is mounted

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

## RELATED LINKS
