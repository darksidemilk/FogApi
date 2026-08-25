# Site
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Description** | **String** |  | [optional] 

## Examples

- Prepare the resource
```powershell
$Site = Initialize-FogApiSite  -Id null `
 -Name null `
 -Description null
```

- Convert the resource to JSON
```powershell
$Site | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

