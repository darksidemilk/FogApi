---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-LastImageTime
schema: 2.0.0
---

# Get-LastImageTime

## SYNOPSIS
Prompts for a serial number, finds the host by that serial number, and returns a string showing the last image time of that host

## SYNTAX

### bySN (Default)
```
Get-LastImageTime [-serialNumber <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### byHostId
```
Get-LastImageTime [-hostId <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### byHost
```
Get-LastImageTime [-fogHost <Object>] [-currentHost] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Searches the imaging log for the hostid and returns the last entries start time and image used in a descriptive string

## EXAMPLES

### EXAMPLE 1
```
Get-LastImageTime
```

Will prompt you to scan/type in a serialnumber (i.e.
via barcode).
Lets say you scan/input 12345678, if that serialnumber belong to a host named "test" it would display a string like this
"Serial number 12345678 belongs to host test, it was last imaged at 2022-08-18 12:19:38 with the image Win-10-21H2"
And return the full object of the host's imaging log

### EXAMPLE 2
```
Get-LastImageTime -currentHost
```

Will get the current computer in fog and return the last image log object.
Will also output a descriptive string, i.e.
if the hostname is test-pc
hostname is test-pc, it was last imaged at 2022-08-18 12:19:38 with the image Win-10-21H2

### EXAMPLE 3
```
Get-LastImageTime -hostID 1234
```

Will get the foghost with the id 1234 and return the last entry in its image log

### EXAMPLE 4
```
$log = Get-LastImageTime -fogHost $hostObj;
```

Will put the last image history log for the given host in the $log variable.
That $log's properties can then be used in other operations

## PARAMETERS

### -serialNumber
The serialnumber to search for, if not specified, it will prompt for input with readhost if none is given

```yaml
Type: Object
Parameter Sets: bySN
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -hostId
Specify the hostid to get the image history for

```yaml
Type: Object
Parameter Sets: byHostId
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -fogHost
specify the fog host object to get the last history for

```yaml
Type: Object
Parameter Sets: byHost
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -currentHost
switch param to get the current host's foghost object and return the last image time

```yaml
Type: SwitchParameter
Parameter Sets: byHost
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
Implemented as part of a feature request found in the forums here https://forums.fogproject.org/post/146276

## RELATED LINKS
