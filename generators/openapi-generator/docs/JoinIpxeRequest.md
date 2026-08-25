# JoinIpxeRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Product** | **String** |  | [optional] 
**Manufacturer** | **String** |  | [optional] 
**Mac** | **String** |  | [optional] 
**Success** | **String** |  | [optional] 
**Failure** | **String** |  | [optional] 
**File** | **String** |  | [optional] 
**Version** | **String** |  | [optional] 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinIpxeRequest = Initialize-FogApiJoinIpxeRequest  -Id null `
 -Product null `
 -Manufacturer null `
 -Mac null `
 -Success null `
 -Failure null `
 -File null `
 -Version null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinIpxeRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

