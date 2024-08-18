---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Add-FogResultData
schema: 2.0.0
---

# Add-FogResultData

## SYNOPSIS
This tests the result of invoke-fogapi to see if its the newer (fog 1.6) version of the api that uses the data property, or if it uses the old specified property
If the data property is missing it is added

## SYNTAX

```
Add-FogResultData [[-result] <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
If the data property of the given result doesn't exist it will find the correct data property name and add the data property with the value of the old api path property
This was created for compatibility between fog 1.5 and fog 1.6.
If you are on fog 1.5.x the old property will still exist in the result

## EXAMPLES

### EXAMPLE 1
```
$result = Invoke-FogApi @apiInvoke;$result = Add-FogResultData $result;
```

If using fog 1.5.x will add $results.data with the value of the results property, $result.tasks if fog 1.6 will do nothing as $result.data already exists

## PARAMETERS

### -result
Should be the output of a invoke-fogapi that has properties from the api result

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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
