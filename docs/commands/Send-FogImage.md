---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Send-FogImage
schema: 2.0.0
---

# Send-FogImage

## SYNOPSIS
Start or schedule a deploy task for a fog host

## SYNTAX

### now (Default)
```
Send-FogImage [-hostId <Object>] [-imageName <String>] [-debugMode] [-NoWol] [-shutdown]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### schedule
```
Send-FogImage [-hostId <Object>] [-StartAtTime <DateTime>] [-imageName <String>] [-debugMode] [-NoWol]
 [-shutdown] [-NoSnapins] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### schedule-byhost
```
Send-FogImage [-fogHost <Object>] [-StartAtTime <DateTime>] [-imageName <String>] [-debugMode] [-NoWol]
 [-shutdown] [-NoSnapins] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### now-byhost
```
Send-FogImage [-fogHost <Object>] [-imageName <String>] [-debugMode] [-NoWol] [-shutdown]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Starts or schedules a deploy task of the currently assigned image on a host

## EXAMPLES

### EXAMPLE 1
```
Deploy-FogImage -hostID "1234"
```

Will queue a deploy task for host 1234 right now

### EXAMPLE 2
```
Push-FogImage -hostID "1234" -StartAtTime (Get-date 8pm)
```

Using the alias name for this command, Will schedule a deploy task for the host of id 1234 at 8pm the same day

### EXAMPLE 3
```
Send-FogImage -hostID "1234" -startAtTime ((Get-Date 8pm).adddays(2)).ToDateTime($null)
```

Using another alias for this command, will schedule a deploy  task for the host 1234 at 8pm 2 days from now.
i.e.
if today was friday, this would schedule it for sunday at 8pm.

## PARAMETERS

### -hostId
the hostid to start the deploy task for

```yaml
Type: Object
Parameter Sets: now, schedule
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -fogHost
fogHost object (get-foghost) that can be brought in from pipeline

```yaml
Type: Object
Parameter Sets: schedule-byhost, now-byhost
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -StartAtTime
The time to start the deploy task, use Get-date to create the required datetime object

```yaml
Type: DateTime
Parameter Sets: schedule, schedule-byhost
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -imageName
The name of the image to deploy, uses currently set image if not specified
Tab completion of your fog server's image names if you're on pwsh 7+

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -debugMode
Switch param to mark the task as a debug task

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
Switch param to indicate the host should shutdown at the end of the task instead of restarting.

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
Switch param for when running a scheduled task, you can choose to set deploysnapins to false so the
assigned snapins aren't auto scheduled too.
Only works in FOG 1.6+

```yaml
Type: SwitchParameter
Parameter Sets: schedule, schedule-byhost
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
The verbs used in the main name and alias names are meant to provide better usability as someone may search for approved powershell verbs 
when looking for this functionality or may simply look for deploy as that is the name of the task in fog.
It just happens to be an approved powershell verb too

## RELATED LINKS
