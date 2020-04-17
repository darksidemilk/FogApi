---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogGroup
schema: 2.0.0
---

# Get-FogGroup

## SYNOPSIS
needs to return the group name of the group that isn't the everyone group
will use groupassociation call to get group id then group id to get group name from group uriPath

## SYNTAX

```
Get-FogGroup [[-hostId] <Int32>] [<CommonParameters>]
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Includes a propietary if block for the organization this was originally written for.
Will be taken out once it is moved, but it is in an if statement as to not affect others 
Was originally meant to find just one group filtering out some global/parent groups.
Altered to find all groups a host is in

## RELATED LINKS
