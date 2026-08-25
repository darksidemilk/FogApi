# Keysequence
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Ascii** | **String** |  | 

## Examples

- Prepare the resource
```powershell
$Keysequence = Initialize-FogApiKeysequence  -Id null `
 -Name null `
 -Ascii null
```

- Convert the resource to JSON
```powershell
$Keysequence | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

