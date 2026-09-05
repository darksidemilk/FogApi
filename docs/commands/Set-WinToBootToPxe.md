---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Set-WinToBootToPxe
schema: 2.0.0
---

# Set-WinToBootToPxe

## SYNOPSIS
Find the pxe boot id and make it the first option in the machine's PERMANENT firmware boot order

## SYNTAX

```
Set-WinToBootToPxe [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Finds this machine's network boot entry and puts it first in the firmware boot order with
\`bcdedit /set {fwbootmgr} displayorder \<id\> /addfirst\`.
Only works in windows, requires admin rights

This change is PERMANENT.
\`{fwbootmgr}\`'s displayorder is the uefi BootOrder variable, so the
machine boots to the network first on every boot from now on, not just the next one, until
something puts the order back.
It also deletes \`{fwbootmgr}\`'s bootsequence, which is the uefi
BootNext variable, so any one shot boot already armed on this machine is cancelled.

Both of those were measured with bcdedit against the raw firmware variables, they are not
inferred from the names.

If what you want is "boot to pxe once, for this FOG task, then go back to normal", use
Set-WinBootNext instead.
That arms BootNext, which the firmware consumes and deletes by
itself, so a machine that never gets imaged is left exactly as it was.

## EXAMPLES

### EXAMPLE 1
```
Set-WinToBootToPxe
```

Will use Get-WinBcdPxeId to find the pxe id and then set that guid as the first boot option in your boot order, permanently

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
Will also remove any runonce or bootsequence entries that might stop the boot order change from
taking place.
On a uefi machine bootsequence IS the BootNext variable, so this cancels a pending
one shot boot as a side effect.

## RELATED LINKS
