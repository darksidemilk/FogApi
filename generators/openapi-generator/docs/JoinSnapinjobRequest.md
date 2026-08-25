# JoinSnapinjobRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**StateID** | **Int32** |  | 
**AbortOnFail** | **String** |  | [optional] [default to "0"]
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinSnapinjobRequest = Initialize-FogApiJoinSnapinjobRequest  -Id null `
 -HostID null `
 -StateID null `
 -AbortOnFail null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinSnapinjobRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

