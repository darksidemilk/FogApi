# JoinSnapingroupassociationRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**SnapinID** | **Int32** |  | 
**StoragegroupID** | **Int32** |  | 
**Primary** | **String** |  | [optional] [default to "0"]
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinSnapingroupassociationRequest = Initialize-FogApiJoinSnapingroupassociationRequest  -Id null `
 -SnapinID null `
 -StoragegroupID null `
 -Primary null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinSnapingroupassociationRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

