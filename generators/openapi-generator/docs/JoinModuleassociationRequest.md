# JoinModuleassociationRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**ModuleID** | **Int32** |  | 
**State** | **String** |  | [optional] 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinModuleassociationRequest = Initialize-FogApiJoinModuleassociationRequest  -Id null `
 -HostID null `
 -ModuleID null `
 -State null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinModuleassociationRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

