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

```
Reset-HostEncryption [[-fogHost] <Object>] [-restartSvc] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Default to getting the current host, but can also pass the object returned from Get-FogHost
and its parameters for any other host.
Removes/resets the pub_key, sec_tok, and sec_time properties of a host so it can be re-encrypted by
the fogservice to form a new connection.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -fogHost
Defaults to getting current host or can pass a host object

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (Get-FogHost)
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
