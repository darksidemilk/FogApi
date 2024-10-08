---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogHost
schema: 2.0.0
---

# Get-FogHost

## SYNOPSIS
Gets the object of a specific fog host

## SYNTAX

### searchTerm (Default)
```
Get-FogHost [-uuid <String>] [-hostName <String>] [-macAddr <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### byID
```
Get-FogHost -hostID <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### serialNumber
```
Get-FogHost -serialNumber <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Searches a new or existing object of hosts for a specific host (or hosts) with search options of uuid, hostname, or mac address
if no search terms are specified then it gets the search terms from your host that is making the request and tries to find your
computer in fog.
IF you specify the id of the host, then only that host is queried for in the api, otherwise it gets all hosts and searches
that object with the given parameters.

## EXAMPLES

### EXAMPLE 1
```
Get-FogHost -hostName MeowMachine
```

This would return the fog details of a host named MeowMachine in your fog instance
If using pwsh 7+ and your FOG service is 1.6 or above, you can tab complete to search for existing hosts by name

### EXAMPLE 2
```
Get-FogHost
```

If you specify no param it will return your current host from fog

### EXAMPLE 3
```
Get-FogHost -hostID 1234
```

Will get the host of id 1234 directly, this is the fastest way to call the function

### EXAMPLE 4
```
Get-FogHost -serialNumber 12345678
```

Will find the given serial number in fog server inventory and then find the host of the hostID that inventory belongs to

## PARAMETERS

### -uuid
the uuid of the host

```yaml
Type: String
Parameter Sets: searchTerm
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -hostName
the hostname of the host, if your FOG version is 1.6 or above you can use tab complete for hostnames

```yaml
Type: String
Parameter Sets: searchTerm
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -macAddr
a mac address linked to the host

```yaml
Type: String
Parameter Sets: searchTerm
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -hostID
{{ Fill hostID Description }}

```yaml
Type: String
Parameter Sets: byID
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -serialNumber
{{ Fill serialNumber Description }}

```yaml
Type: String
Parameter Sets: serialNumber
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
