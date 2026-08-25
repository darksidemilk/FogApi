# Nodefailure
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**StoragenodeID** | **Int32** |  | 
**TaskID** | **Int32** |  | 
**HostID** | **Int32** |  | 
**StoragegroupID** | **Int32** |  | 
**FailureTime** | **System.DateTime** |  | 
**Storagenode** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Storagegroup** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**VarHost** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Task** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 

## Examples

- Prepare the resource
```powershell
$Nodefailure = Initialize-FogApiNodefailure  -Id null `
 -StoragenodeID null `
 -TaskID null `
 -HostID null `
 -StoragegroupID null `
 -FailureTime null `
 -Storagenode null `
 -Storagegroup null `
 -VarHost null `
 -Task null
```

- Convert the resource to JSON
```powershell
$Nodefailure | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

