---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Remove-FogHostGroup
schema: 2.0.0
---

# Remove-FogHostGroup

## SYNOPSIS
Removes a host from a fog group

## SYNTAX

### byHost (Default)
```
Remove-FogHostGroup [-fogHost <Object>] -groupID <Object> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### byId
```
Remove-FogHostGroup [-hostID <Object>] -groupID <Object> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Finds the group association entry linking a host to a group and deletes it, removing the host from that group's membership.

## EXAMPLES

### EXAMPLE 1
```
Remove-FogHostGroup -hostID 42 -groupID 3
```

Removes the host with id 42 from the group with id 3.
A successful delete returns an empty response from the fog server.

Expected output:
""

### EXAMPLE 2
```
Get-FogHost -hostName MeowMachine | Remove-FogHostGroup -groupID 5
```

Finds the host by name and removes it from the group with id 5.
A successful delete returns an empty response from the fog server.

Expected output:
""

## PARAMETERS

### -fogHost
A fog host object (e.g.
from Get-FogHost) to remove from the group.
Supports pipeline input.

```yaml
Type: Object
Parameter Sets: byHost
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -hostID
Can either be the id number of the host object or the name of the host in a string

```yaml
Type: Object
Parameter Sets: byId
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -groupID
The id of the group to remove the host from

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
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

## RELATED LINKS
