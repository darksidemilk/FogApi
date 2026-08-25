# Imagetype
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Type** | **String** |  | 

## Examples

- Prepare the resource
```powershell
$Imagetype = Initialize-FogApiImagetype  -Id null `
 -Name null `
 -Type null
```

- Convert the resource to JSON
```powershell
$Imagetype | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

