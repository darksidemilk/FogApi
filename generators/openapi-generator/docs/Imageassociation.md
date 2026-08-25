# Imageassociation
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**ImageID** | **Int32** |  | 
**StoragegroupID** | **Int32** |  | 
**Primary** | **String** |  | [optional] [default to "0"]

## Examples

- Prepare the resource
```powershell
$Imageassociation = Initialize-FogApiImageassociation  -Id null `
 -ImageID null `
 -StoragegroupID null `
 -Primary null
```

- Convert the resource to JSON
```powershell
$Imageassociation | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

