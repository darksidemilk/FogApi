---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Clear-WinBootNext
schema: 2.0.0
---

# Clear-WinBootNext

## SYNOPSIS
Cancels a pending one shot network boot by deleting the uefi BootNext variable

## SYNTAX

```
Clear-WinBootNext [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Deletes BootNext, so the next boot follows the normal boot order again.

Only needed when the reboot the arming was for is not going to happen.
A BootNext left
behind would send the machine to the network on whatever boot came next, for whatever
reason, which is a surprise nobody wants.
In the normal case the firmware deletes the
variable itself as it consumes it and there is nothing to clean up.

## EXAMPLES

### EXAMPLE 1
```
Clear-WinBootNext
```

Cancels any pending one shot boot

## PARAMETERS

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
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
Windows only, and needs SeSystemEnvironmentPrivilege enabled, so an elevated prompt or the
SYSTEM account.

## RELATED LINKS
