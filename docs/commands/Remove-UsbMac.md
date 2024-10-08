---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Remove-UsbMac
schema: 2.0.0
---

# Remove-UsbMac

## SYNOPSIS
A cmdlet that uses invoke-fogapi to remove a given list of usb mac address from a host

## SYNTAX

### byHost
```
Remove-UsbMac [-hostObj <Object>] [-usbMacs <String[]>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### byName
```
Remove-UsbMac [-hostName <String>] [-usbMacs <String[]>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
When a wireless device is imaged with a usb ethernet adapter, it should be removed when it's done

## EXAMPLES

### EXAMPLE 1
```
Remove-UsbMacs -fogServer "foggy" -usbMacs @("01:23:45:67:89:10", "00:00:00:00:00:00")
```

## PARAMETERS

### -hostObj
{{ Fill hostObj Description }}

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

### -hostName
the hostname to remove the usb macs from, defaults to current hostname

```yaml
Type: String
Parameter Sets: byName
Aliases:

Required: False
Position: Named
Default value: "$(hostname)"
Accept pipeline input: False
Accept wildcard characters: False
```

### -usbMacs
a string of mac addresses like this @("01:23:45:67:89:10", "00:00:00:00:00:00")

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
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
online version of help goes to fog forum post where the idea was conceived
There are try catch blocks so the original working code before the get, update, and remove functions existed can remain as a fallback
See also https://forums.fogproject.org/topic/10837/usb-ethernet-adapter-mac-s-for-imaging-multiple-hosts-universal-imaging-nics-wired-nic-for-all-wireless-devices/14

## RELATED LINKS
