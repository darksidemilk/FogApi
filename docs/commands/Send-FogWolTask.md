---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Send-FogWolTask
schema: 2.0.0
---

# Send-FogWolTask

## SYNOPSIS
Sends a wake on task to a given host by host object gotten with get-foghost or by the name of the host

## SYNTAX

### byHostObject
```
Send-FogWolTask [-hostObj <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### byname
```
Send-FogWolTask [-computername <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Creates a new fog task of id 14 for a wake on lan task.
Will cause fog to send a magic packet to the 
mac addresses registered for the given host.

## EXAMPLES

### EXAMPLE 1
```
Send-FogWolTask -computername "some-computer"
```

Will send a magic computer to the computer some-computer from the fog server;

### EXAMPLE 2
```
$sleepers = (Get-foghosts | ? name -in ((Get-ADComputer -Filter '*' -SearchBase 'ou=someOU,dc=company,dc=local').name)); $sleepers | % {Send-FogWolTask -hostObj $_}
```

Will find the names of the computers in the given ou via the distinguished name string in the searchbase param.
It will find the fog host objects that match those names and put them in the $sleepers variable
It will go through each of the $sleepers and send a wake on lan task

## PARAMETERS

### -hostObj
The foghost object gotten with get-foghost

```yaml
Type: Object
Parameter Sets: byHostObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -computername
The name of the computer to get the fog host of

```yaml
Type: String
Parameter Sets: byname
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
Created per this forum post https://forums.fogproject.org/topic/16867/api-wake-on-lan?_=1686084315380

## RELATED LINKS
