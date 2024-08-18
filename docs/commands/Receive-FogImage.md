---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Receive-FogImage
schema: 2.0.0
---

# Receive-FogImage

## SYNOPSIS
Starts or schedules a capture task on a given host

## SYNTAX

### now (Default)
```
Receive-FogImage [-hostId <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### schedule
```
Receive-FogImage [-hostId <Object>] [-StartAtTime <DateTime>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Starts a capture task to receive a new version of an image in fog

## EXAMPLES

### EXAMPLE 1
```
Receive-FogImage -hostID "1234"
```

Will queue a capture task for host 1234 right now

### EXAMPLE 2
```
Capture-FogImage -hostID "1234" -StartAtTime (Get-date 8pm)
```

Using the alias name for this command, Will schedule a capture task for the host of id 1234 at 8pm the same day

### EXAMPLE 3
```
Pull-FogImage -hostID "1234" -startAtTime ((Get-Date 8pm).adddays(2)).ToDateTime($null)
```

Using another alias for this command, will schedule a capture task for the host 1234 at 8pm 2 days from now.
i.e.
if today was friday, this would schedule it for sunday at 8pm.

## PARAMETERS

### -hostId
The id of the host to capture from

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartAtTime
When to start to capture, if not given will start now

```yaml
Type: DateTime
Parameter Sets: schedule
Aliases:

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
Pull and Capture are not powershell approved verbs, they were used as aliases to match the opposite 
Push-Image alias and to match the name of the task in the fog system but that caused a constant warning when importing the module
Receive is an approved verb and the closest one to what this does, Save-FogImage is another alias as is Invoke-FogImageCapture.

## RELATED LINKS
