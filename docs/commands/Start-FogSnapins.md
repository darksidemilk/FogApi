---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Start-FogSnapins
schema: 2.0.0
---

# Start-FogSnapins

## SYNOPSIS
Starts all associated snapins of a host

## SYNTAX

### byObj
```
Start-FogSnapins [-fogHost <Object>] [-taskTypeid <Object>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### byid
```
Start-FogSnapins [-hostid <Object>] [-taskTypeid <Object>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Starts the allsnapins task on a provided hostid

## EXAMPLES

### EXAMPLE 1
```
Start-FogSnapins
```

will get the current host's id and start all snapins on it

### EXAMPLE 2
```
Start-FogSnapins -hostid 1234
```

will start all snapins on the host with the id 1234

### EXAMPLE 3
```
Get-foghost -hostname 'somehost' | Start-FogSnapins
```

will get the host object for the host named 'somehost' and start all snapins on it

## PARAMETERS

### -fogHost
the foghost object to start the snapin task on, should be an object returned from get-foghost
Can also be brought in via pipeline

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

### -hostid
the hostid to start the task on

```yaml
Type: Object
Parameter Sets: byid
Aliases:

Required: False
Position: Named
Default value: ((Get-FogHost).id)
Accept pipeline input: False
Accept wildcard characters: False
```

### -taskTypeid
the id of the task to start, defaults to 12

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 12
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
