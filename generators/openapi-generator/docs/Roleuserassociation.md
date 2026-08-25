# Roleuserassociation
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | [optional] 
**RoleID** | **Int32** |  | 
**UserID** | **Int32** |  | 

## Examples

- Prepare the resource
```powershell
$Roleuserassociation = Initialize-FogApiRoleuserassociation  -Id null `
 -Name null `
 -RoleID null `
 -UserID null
```

- Convert the resource to JSON
```powershell
$Roleuserassociation | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

