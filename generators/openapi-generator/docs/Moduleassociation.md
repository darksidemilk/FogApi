# Moduleassociation
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**ModuleID** | **Int32** |  | 
**State** | **String** |  | [optional] 

## Examples

- Prepare the resource
```powershell
$Moduleassociation = Initialize-FogApiModuleassociation  -Id null `
 -HostID null `
 -ModuleID null `
 -State null
```

- Convert the resource to JSON
```powershell
$Moduleassociation | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

