# Oui
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Prefix** | **String** |  | 
**Name** | **String** |  | 

## Examples

- Prepare the resource
```powershell
$Oui = Initialize-FogApiOui  -Id null `
 -Prefix null `
 -Name null
```

- Convert the resource to JSON
```powershell
$Oui | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

