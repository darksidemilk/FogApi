---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogScheduledTasks
schema: 2.0.0
---

# Get-FogScheduledTasks

## SYNOPSIS
Gets the current Scheduled tasks, by default only active scheduled tasks

## SYNTAX

```
Get-FogScheduledTasks [-all] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets the current Scheduled tasks and expands them into an object

## EXAMPLES

### EXAMPLE 1
```
Get-FogScheduledTasks
```

This will list any scheduled tasks and their properties

### EXAMPLE 2
```
Get-FogScheduledTasks | Where-Object hostid -eq (Get-Foghost -hostname "comp-name").id
```

This will list any scheduled tasks for the host with the hostname "comp-name" by searching for the hostid of that computer and filtering the results to the hostid.

## PARAMETERS

### -all
If specified, will return all scheduled tasks, not just active ones.
This is useful for viewing historically scheduled tasks that have been completed or are no longer active.

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
