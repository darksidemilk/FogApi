# JoinModuleRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**ShortName** | **String** |  | 
**Description** | **String** |  | [optional] 
**IsDefault** | **Int32** |  | [optional] [default to 1]
**Hosts** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinModuleRequest = Initialize-FogApiJoinModuleRequest  -Id null `
 -Name null `
 -ShortName null `
 -Description null `
 -IsDefault null `
 -Hosts null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinModuleRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

