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
Send-FogImage [-hostId <Object>] [<CommonParameters>]
```

### schedule
```
Send-FogImage [-hostId <Object>] [-StartAtTime <DateTime>] [<CommonParameters>]
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
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartAtTime
The time to start the deploy task, use Get-date to create the required datetime object

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
The verbs used in the main name and alias names are meant to provide better usability as someone may search for approved powershell verbs 
when looking for this functionality or may simply look for deploy as that is the name of the task in fog.
It just happens to be an approved powershell verb too

## RELATED LINKS
