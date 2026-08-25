# Os
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Description** | **String** |  | [optional] 

## Examples

- Prepare the resource
```powershell
$Os = Initialize-FogApiOs  -Id null `
 -Name null `
 -Description null
```

- Convert the resource to JSON
```powershell
$Os | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

