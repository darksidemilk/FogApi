# JoinPowermanagementRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**Min** | **String** |  | [optional] 
**Hour** | **String** |  | [optional] 
**Dom** | **String** |  | [optional] 
**Month** | **String** |  | [optional] 
**Dow** | **String** |  | [optional] 
**OnDemand** | **String** |  | [optional] [default to "0"]
**Action** | **String** |  | 
**Hosts** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinPowermanagementRequest = Initialize-FogApiJoinPowermanagementRequest  -Id null `
 -HostID null `
 -Min null `
 -Hour null `
 -Dom null `
 -Month null `
 -Dow null `
 -OnDemand null `
 -Action null `
 -Hosts null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinPowermanagementRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

