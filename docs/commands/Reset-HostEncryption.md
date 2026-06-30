---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Reset-HostEncryption
schema: 2.0.0
---

# Reset-HostEncryption

## SYNOPSIS
Reset the host encryption data on a given host

## SYNTAX

### HostObject
```
Reset-HostEncryption [-fogHost <Object>] [-restartSvc] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### HostID
```
Reset-HostEncryption [-fogHostID <Object>] [-restartSvc] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Default to getting the current host, but can also pass the object returned from Get-FogHost
and its parameters for any other host.
Removes/resets the pub_key, sec_tok, and sec_time properties of a host so it can be re-encrypted by
the fogservice to form a new connection.

## EXAMPLES

### EXAMPLE 1
```
Reset-HostEncryption -fogHostID 1234 -restartSvc
```

This example resets the encryption data for the host with ID 1234 and restarts the fog service to force a re-encryption.

### EXAMPLE 2
```
Reset-HostEncryption -fogHost (Get-FogHost -hostID 1234)
```

This example resets the encryption data for the host with ID 1234 using the host object returned from Get-FogHost.

### EXAMPLE 3
```
Reset-HostEncryption -restartSvc
```

This example resets the encryption data for the current host running the command and restarts the fog service to force a re-encryption.

## PARAMETERS

### -fogHost
Defaults to getting current host or can pass a host object

```yaml
Type: Object
Parameter Sets: HostObject
Aliases:

Required: False
Position: Named
Default value: (Get-FogHost)
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -fogHostID
The fogHostID parameter allows you to pass a host ID to reset the encryption data for that host.

```yaml
Type: Object
Parameter Sets: HostID
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -restartSvc
The restartSvc switch will restart the fog service
forcing a more immediate re-encryption and connection.
This currently only works when used on the local computer
you are resetting.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
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

## RELATED LINKS
