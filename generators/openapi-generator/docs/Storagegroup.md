# Storagegroup
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Description** | **String** |  | [optional] 
**Trustedcidrs** | **String** |  | [optional] 

## Examples

- Prepare the resource
```powershell
$Storagegroup = Initialize-FogApiStoragegroup  -Id null `
 -Name null `
 -Description null `
 -Trustedcidrs null
```

- Convert the resource to JSON
```powershell
$Storagegroup | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

