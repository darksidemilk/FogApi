# Usergroup
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Description** | **String** |  | [optional] 
**Users** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Roles** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 

## Examples

- Prepare the resource
```powershell
$Usergroup = Initialize-FogApiUsergroup  -Id null `
 -Name null `
 -Description null `
 -Users null `
 -Roles null
```

- Convert the resource to JSON
```powershell
$Usergroup | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

