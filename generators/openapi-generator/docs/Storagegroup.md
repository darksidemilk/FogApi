# Storagegroup
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Description** | **String** |  | [optional] 
**Trustedcidrs** | **String** |  | [optional] 
**Allnodes** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Enablednodes** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Usedtasks** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Images** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Snapins** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 

## Examples

- Prepare the resource
```powershell
$Storagegroup = Initialize-FogApiStoragegroup  -Id null `
 -Name null `
 -Description null `
 -Trustedcidrs null `
 -Allnodes null `
 -Enablednodes null `
 -Usedtasks null `
 -Images null `
 -Snapins null
```

- Convert the resource to JSON
```powershell
$Storagegroup | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

