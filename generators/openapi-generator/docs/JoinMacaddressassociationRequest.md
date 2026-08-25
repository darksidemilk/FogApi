# JoinMacaddressassociationRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**Mac** | **String** |  | 
**Description** | **String** |  | [optional] 
**Pending** | **String** |  | [optional] [default to "0"]
**Primary** | **String** |  | [optional] [default to "0"]
**ClientIgnore** | **String** |  | [optional] [default to "0"]
**ImageIgnore** | **String** |  | [optional] [default to "0"]
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinMacaddressassociationRequest = Initialize-FogApiJoinMacaddressassociationRequest  -Id null `
 -HostID null `
 -Mac null `
 -Description null `
 -Pending null `
 -Primary null `
 -ClientIgnore null `
 -ImageIgnore null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinMacaddressassociationRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

