---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Send-FogGroupTask
schema: 2.0.0
---

# Send-FogGroupTask

## SYNOPSIS
Queues a task against every host in a fog group at once

## SYNTAX

### byObj
```
Send-FogGroupTask [-groupObj <Object>] [-taskTypeID <Object>] [-StartAtTime <DateTime>] [-debugMode] [-NoWol]
 [-shutdown] [-NoSnapins] [-bypassbitlocker] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### byId
```
Send-FogGroupTask -groupID <Object> [-taskTypeID <Object>] [-StartAtTime <DateTime>] [-debugMode] [-NoWol]
 [-shutdown] [-NoSnapins] [-bypassbitlocker] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Creates an immediate task (or, if -StartAtTime is given, a scheduled task) against a whole group of hosts in one call,
instead of looping New-FogObject/Send-FogImage per host.
Uses taskTypeID 1 (deploy) by default, the same default fog uses for a normal image deploy task.

## EXAMPLES

### EXAMPLE 1
```
Send-FogGroupTask -groupID 7 -taskTypeID 14
```

Queues an immediate wake-up task for every host in the group with id 7.
Use the default taskTypeID of 1 to queue a deploy task instead.

Expected output:
""

### EXAMPLE 2
```
Get-FogGroupByName "TestGroup" | Send-FogGroupTask -taskTypeID 14 -StartAtTime ((Get-Date).AddHours(2))
```

Finds the group named "TestGroup" and schedules a wake-up task for every host in it 2 hours from now,
returning the created scheduled task marked as a group task.

Expected output:
{ "type": "S", "isGroupTask": "1" }

## PARAMETERS

### -groupObj
A fog group object (e.g.
from Get-FogGroups) to queue the task for.
Supports pipeline input.

```yaml
Type: Object
Parameter Sets: byObj
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -groupID
The id of the group to queue the task for

```yaml
Type: Object
Parameter Sets: byId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -taskTypeID
The fog task type id to queue, defaults to 1 (deploy).
See your fog server's task type list for other values (e.g.
capture, memtest, etc.)

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartAtTime
The time to start the task, use Get-date to create the required datetime object.
If omitted the task is queued to start immediately.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -debugMode
Switch param to mark the task as a debug task.
Only applies to immediate tasks.

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

### -NoWol
Switch param to not use wake on lan in the task, default is to use wake on lan

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

### -shutdown
Switch param to indicate hosts should shutdown at the end of the task instead of restarting.

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

### -NoSnapins
Switch param for scheduled tasks, sets deploysnapins to false so assigned snapins aren't auto scheduled too.
Only works in FOG 1.6+ and only with scheduled tasks.

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

### -bypassbitlocker
Switch param to bypass bitlocker checks, this will set the bitlocker flag to 1 in the task, this is the 'other5' property.

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
Verified against the fog server source (FOGProject/fogproject, working-1.6 branch, packages/web/lib/router/route.class.php and
packages/web/lib/fog/scheduledtask.class.php):
- Immediate group tasks use the "group" coreTaskObject (POST group/{id}/task), routed to Route::task() which calls
  Group::createImagePackage() when the target class is a Group.
Reads taskTypeID, taskName, shutdown, debug, wol, deploySnapins.
- Scheduled group tasks go through the generic scheduledtask create() route.
The scheduledtask table has no separate groupID column -
  "isGroupTask":"1" instead repurposes the "hostID" field (db column stGroupHostID) to hold the group id, so this cmdlet sends
  "hostID":"$groupID" rather than a "groupID" field.
The scheduledtask create route only maps JSON keys that literally match its
  databaseFields, so the task's name field must be sent as "name", not "taskName".

## RELATED LINKS
