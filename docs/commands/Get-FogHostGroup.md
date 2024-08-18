---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogHostGroup
schema: 2.0.0
---

# Get-FogHostGroup

## SYNOPSIS
returns the group objects that a host belongs to

## SYNTAX

```
Get-FogHostGroup [[-hostId] <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
requires the id of the host you want the groups that aren't the everyone group for

## EXAMPLES

### EXAMPLE 1
```
Get-FogGroup -hostId ((Get-FogHost -hostname "computerName").id)
```

Gets the fog group membership(s) of the fog host with the name computerName

## PARAMETERS

### -hostId
The hostid to get the group memberships of

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: 0
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
