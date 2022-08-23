---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogSecsSinceEpoch
schema: 2.0.0
---

# Get-FogSecsSinceEpoch

## SYNOPSIS
Gets seconds since 1970 epoch

## SYNTAX

```
Get-FogSecsSinceEpoch [[-scheduleDate] <Object>]
```

## DESCRIPTION
Gets seconds since 1970 epoch to give the unix time value

## EXAMPLES

### EXAMPLE 1
```
Get-SecsSinceEpoch
```

returns the unixtime value of the current time

## PARAMETERS

### -scheduleDate
the date to get the unixtime of defaults to current datetime

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (Get-Date)
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES
Created to be used with creating scheduled tasks in fog

## RELATED LINKS
