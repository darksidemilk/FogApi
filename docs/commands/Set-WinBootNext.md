---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Set-WinBootNext
schema: 2.0.0
---

# Set-WinBootNext

## SYNOPSIS
Arms a one shot network boot by setting the uefi BootNext variable

## SYNTAX

### find (Default)
```
Set-WinBootNext [-macAddress <String>] [-passThru] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### option
```
Set-WinBootNext [[-bootOption] <Object>] [-passThru] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### number
```
Set-WinBootNext [-bootNumber <UInt16>] [-passThru] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Sets BootNext to a network boot entry, so the very next boot goes to pxe and every boot
after that is unchanged.
The firmware consumes and deletes BootNext as it uses it, so there
is nothing to undo afterwards and nothing left behind if the machine is never imaged.

This is the one to use before rebooting a machine into a FOG task.
Set-WinToBootToPxe is the
other half of the story and does something meaningfully different: it rewrites the permanent
firmware boot order with \`bcdedit /set {fwbootmgr} displayorder /addfirst\`, which leaves the
machine booting to the network first forever, and it deletes any pending BootNext on the way
past.
Prefer this cmdlet unless a permanent reorder is what you actually want.

With no parameters it arms the entry Get-WinNetBootOption picks, which is found by device
path rather than by searching descriptions for likely words.

## EXAMPLES

### EXAMPLE 1
```
Set-WinBootNext
```

Finds this machine's network boot entry and arms it for the next boot only

### EXAMPLE 2
```
Set-WinBootNext -macAddress 00-11-22-33-44-55 -passThru
```

Arms the network entry belonging to that nic and returns it

### EXAMPLE 3
```
Get-WinNetBootOption | Select-Object -First 1 | Set-WinBootNext
```

The same thing done explicitly, when you want to see what will be armed before arming it

## PARAMETERS

### -bootOption
A boot option from Get-WinNetBootOption.
Accepts pipeline input.

```yaml
Type: Object
Parameter Sets: option
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -bootNumber
Arm this boot number directly, ie 3 for Boot0003.
For the case where you know the entry and
do not want it looked up.

```yaml
Type: UInt16
Parameter Sets: number
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -macAddress
Arm the network entry belonging to this nic, for a machine with more than one.

```yaml
Type: String
Parameter Sets: find
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -passThru
Return the option that was armed instead of nothing.

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
Use Get-WinBootNext to confirm it stuck and Clear-WinBootNext to cancel it.

## RELATED LINKS
