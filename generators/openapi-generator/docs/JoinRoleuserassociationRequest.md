# JoinRoleuserassociationRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | [optional] 
**RoleID** | **Int32** |  | 
**UserID** | **Int32** |  | 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinRoleuserassociationRequest = Initialize-FogApiJoinRoleuserassociationRequest  -Id null `
 -Name null `
 -RoleID null `
 -UserID null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinRoleuserassociationRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

