---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Resolve-HostID
schema: 2.0.0
---

# Resolve-HostID

## SYNOPSIS
Validate the input is a hostid integer

## SYNTAX

```
Resolve-HostID [[-hostID] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Tests if the value can be cast as an int, if not then see if it is the hostname, if not that, see if it is the host object, otherwise return null

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -hostID
the hostid to validate, if none is given, will get the host object of the current host

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (Get-foghost).id
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
