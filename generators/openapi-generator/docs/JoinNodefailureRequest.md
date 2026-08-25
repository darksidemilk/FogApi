# JoinNodefailureRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**StoragenodeID** | **Int32** |  | 
**TaskID** | **Int32** |  | 
**HostID** | **Int32** |  | 
**StoragegroupID** | **Int32** |  | 
**FailureTime** | **System.DateTime** |  | 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinNodefailureRequest = Initialize-FogApiJoinNodefailureRequest  -Id null `
 -StoragenodeID null `
 -TaskID null `
 -HostID null `
 -StoragegroupID null `
 -FailureTime null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinNodefailureRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

