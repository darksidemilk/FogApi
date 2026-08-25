# Roleusergroupassociation
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | [optional] 
**UsergroupID** | **Int32** |  | 
**RoleID** | **Int32** |  | 

## Examples

- Prepare the resource
```powershell
$Roleusergroupassociation = Initialize-FogApiRoleusergroupassociation  -Id null `
 -Name null `
 -UsergroupID null `
 -RoleID null
```

- Convert the resource to JSON
```powershell
$Roleusergroupassociation | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

