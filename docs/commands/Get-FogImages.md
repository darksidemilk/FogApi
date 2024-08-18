---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Get-FogImages
schema: 2.0.0
---

# Get-FogImages

## SYNOPSIS
Returns an object of the images defined in your fogserver

## SYNTAX

```
Get-FogImages [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns the images from your fog server with all their properties

## EXAMPLES

### EXAMPLE 1
```
$images = Get-FogImages; $images | select id,name
```

Gets all the fog images and then lists them with just the image id and names

## PARAMETERS

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
