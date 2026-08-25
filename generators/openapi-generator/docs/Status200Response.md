# Status200Response
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Version** | **String** |  | [optional] 
**Paging** | [**Status200ResponsePaging**](Status200ResponsePaging.md) |  | [optional] 
**Msg** | **String** |  | [optional] 

## Examples

- Prepare the resource
```powershell
$Status200Response = Initialize-FogApiStatus200Response  -Version null `
 -Paging null `
 -Msg null
```

- Convert the resource to JSON
```powershell
$Status200Response | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

