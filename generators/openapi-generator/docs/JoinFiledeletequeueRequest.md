# JoinFiledeletequeueRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Path** | **String** |  | 
**StoragegroupID** | **Int32** |  | 
**CompletedTime** | **System.DateTime** |  | [optional] 
**StateID** | **Int32** |  | [optional] [default to 0]
**Pathtype** | **String** |  | 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinFiledeletequeueRequest = Initialize-FogApiJoinFiledeletequeueRequest  -Id null `
 -Path null `
 -StoragegroupID null `
 -CompletedTime null `
 -StateID null `
 -Pathtype null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinFiledeletequeueRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

