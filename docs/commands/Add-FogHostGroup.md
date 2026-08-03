---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Add-FogHostGroup
schema: 2.0.0
---

# Add-FogHostGroup

## SYNOPSIS
Adds a host to a fog group

## SYNTAX

### byHost (Default)
```
Add-FogHostGroup [-fogHost <Object>] -groupID <Object> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### byId
```
Add-FogHostGroup [-hostID <Object>] -groupID <Object> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Creates a group association entry linking a host to a group, adding the host as a member of that group.
Checks for an existing association first and skips creating a duplicate if the host is already a member of the group.

## EXAMPLES

### EXAMPLE 1
```
Add-FogHostGroup -hostID 42 -groupID 7
```

Adds the host with id 42 to the group with id 7, returning the created group association

Expected output:
{ "hostID": "42", "groupID": "7" }

### EXAMPLE 2
```
Get-FogHost -hostName MeowMachine | Add-FogHostGroup -groupID 7
```

Finds the host by name and adds it to the group with id 7

Expected output:
{ "hostID": "42", "groupID": "7" }

## PARAMETERS

### -fogHost
A fog host object (e.g.
from Get-FogHost) to add to the group.
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
The id of the group to add the host to

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
