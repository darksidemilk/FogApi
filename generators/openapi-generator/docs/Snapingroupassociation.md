# Snapingroupassociation
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**SnapinID** | **Int32** |  | 
**StoragegroupID** | **Int32** |  | 
**Primary** | **String** |  | [optional] [default to "0"]
**Snapin** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Storagegroup** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 

## Examples

- Prepare the resource
```powershell
$Snapingroupassociation = Initialize-FogApiSnapingroupassociation  -Id null `
 -SnapinID null `
 -StoragegroupID null `
 -Primary null `
 -Snapin null `
 -Storagegroup null
```

- Convert the resource to JSON
```powershell
$Snapingroupassociation | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

