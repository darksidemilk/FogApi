---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Test-StringNotNullOrEmpty
schema: 2.0.0
---

# Test-StringNotNullOrEmpty

## SYNOPSIS
Returns true if passed in object is a string that is not null, empty, or whitespace

## SYNTAX

```
Test-StringNotNullOrEmpty [[-str] <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Uses built in string functions to test if a given string is null, empty or whitespace
if it is not any of these things and has valid content, this returns true otherwise false

## EXAMPLES

### EXAMPLE 1
```
Test-StringNotNullOrEmpty "An example"
```

Will return true as it is a valid string with content

### EXAMPLE 2
```
$s = ""; Test-StringNotNullOrEmpty $s;
```

Will return false as this is an empty string.

### EXAMPLE 3
```
$str = " "; $str | Test-StringNotNullOrEmpty
```

Will return false as this string is just whitespace

## PARAMETERS

### -str
String to test

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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
Meant to simplify input validation tests as test-string $param or $value | test-string is easier to type in an if statement than
doing \[string\]::isnullorempty($str) along with \[string\]::isnullorwhitespace($str)

## RELATED LINKS
