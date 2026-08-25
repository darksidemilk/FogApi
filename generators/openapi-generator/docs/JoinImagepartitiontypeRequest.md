# JoinImagepartitiontypeRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Type** | **String** |  | 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinImagepartitiontypeRequest = Initialize-FogApiJoinImagepartitiontypeRequest  -Id null `
 -Name null `
 -Type null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinImagepartitiontypeRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

