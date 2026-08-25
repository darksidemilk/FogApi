# JoinGroupassociationRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**GroupID** | **Int32** |  | 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinGroupassociationRequest = Initialize-FogApiJoinGroupassociationRequest  -Id null `
 -HostID null `
 -GroupID null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinGroupassociationRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

