---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Update-FogObject
schema: 2.0.0
---

# Update-FogObject

## SYNOPSIS
Update/patch/edit api calls

## SYNTAX

```
Update-FogObject [[-type] <String>] [[-jsonData] <Object>] [[-IDofObject] <String>] [[-uri] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Runs update calls to the api

## EXAMPLES

### EXAMPLE 1
```
$h = get-foghost; $h.ADUser = 'ldapBind'; Update-FogObject -type object -coreObject host -jsonData ($h | select-object aduser | ConvertTo-Json -Compress) -IDofObject $h.id -Verbose
```

Will update the ADUser field on the current host to be 'ldapbind' Note that when you update a host, you should not include the name field in the json if you are not changing the name.
You can also set other fields on the local $h object and update all changed fields excluding an unchanged name by using $h | select-object -excludeproperty name

## PARAMETERS

### -type
the type of fog object

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -jsonData
the json data string.
You can use convertto-json to pass powershell objects in

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IDofObject
The ID of the object

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -uri
The explicit uri to use if you run into issues, the issues that caused the need for this originally have been resolved, but kept it for safety

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
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
If you are updating a fog host object, and your json includes the name of the host, but that name isn't changing, you'll get an error.
You should omit the name from the json in such updates
i.e.
if your fog host name is 'computer1' and you pass in a json string link {"name":"computer1","ADUser":"ldapBind"} you will get an error, but if the name is changing or you omit it, it will work without issue.
This only affects the name field

## RELATED LINKS
