# Usergroupmember
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | [optional] 
**UsergroupID** | **Int32** |  | 
**UserID** | **Int32** |  | 

## Examples

- Prepare the resource
```powershell
$Usergroupmember = Initialize-FogApiUsergroupmember  -Id null `
 -Name null `
 -UsergroupID null `
 -UserID null
```

- Convert the resource to JSON
```powershell
$Usergroupmember | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

