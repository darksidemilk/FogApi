---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Set-FogHostImage
schema: 2.0.0
---

# Set-FogHostImage

## SYNOPSIS
Function to set a given image object to a host by its id

## SYNTAX

```
Set-FogHostImage [-hostID] <Object> [[-fogImage] <Object>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Function to set a given image object to a host by its id
Will be expanded for better usability in the future

## EXAMPLES

### EXAMPLE 1
```
$foghost = get-foghost -hostid 1234; $imageName = 'MyImage'; $fogImages = Get-FogImages; $fogHost = Set-FogHostImage -hostId $fogHost.id -fogImage ($fogImages | Where-Object name -eq $imageName)
```

Will set the image with the name of MyImage to the host with the id of 1234

## PARAMETERS

### -hostID
the host id to set an image on

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -fogImage
the image object gotten from get-fogimages

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
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
