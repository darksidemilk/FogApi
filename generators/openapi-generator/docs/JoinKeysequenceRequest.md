# JoinKeysequenceRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Ascii** | **String** |  | 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinKeysequenceRequest = Initialize-FogApiJoinKeysequenceRequest  -Id null `
 -Name null `
 -Ascii null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinKeysequenceRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

