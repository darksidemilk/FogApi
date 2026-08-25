# Rolepermission
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**RoleID** | **Int32** |  | 
**Name** | **String** |  | 

## Examples

- Prepare the resource
```powershell
$Rolepermission = Initialize-FogApiRolepermission  -Id null `
 -RoleID null `
 -Name null
```

- Convert the resource to JSON
```powershell
$Rolepermission | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

