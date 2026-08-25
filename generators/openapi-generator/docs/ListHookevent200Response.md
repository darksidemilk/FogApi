# ListHookevent200Response
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Draw** | **Int32** |  | [optional] 
**RecordsTotal** | **Int32** | Total rows the caller may see, unfiltered. For a site-restricted user this is the total within their sites, not the server total. | [optional] 
**RecordsFiltered** | **Int32** | Rows matching the filter, within what the caller may see. A real total, including for site-restricted users. | [optional] 
**RecordsReturned** | **Int32** | Rows in this page. | [optional] 
**Truncated** | **Boolean** | True only when the server capped an unbounded request at MAX_ROWS. Never set when the caller sent start/length. | [optional] 
**Lang** | **String** |  | [optional] 
**VarData** | [**Hookevent[]**](Hookevent.md) |  | [optional] 
**FirstUrl** | **String** |  | [optional] 
**PrevUrl** | **String** |  | [optional] 
**NextUrl** | **String** | Null when this is the last page. | [optional] 
**LastUrl** | **String** |  | [optional] 

## Examples

- Prepare the resource
```powershell
$ListHookevent200Response = Initialize-FogApiListHookevent200Response  -Draw null `
 -RecordsTotal null `
 -RecordsFiltered null `
 -RecordsReturned null `
 -Truncated null `
 -Lang null `
 -VarData null `
 -FirstUrl null `
 -PrevUrl null `
 -NextUrl null `
 -LastUrl null
```

- Convert the resource to JSON
```powershell
$ListHookevent200Response | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

