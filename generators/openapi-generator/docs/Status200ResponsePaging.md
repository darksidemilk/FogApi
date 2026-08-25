# Status200ResponsePaging
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**MaxRows** | **Int32** | Row cap applied to a list request that omits start, asks for length&#x3D;-1, or sends a negative length. An explicit non-negative start with a positive length is served verbatim. | [optional] 
**ExpandMaxItems** | **Int32** | Page size cap applied to an expand request even when a larger length was asked for, so a page can be smaller than requested. Advance by the rows returned, not the length requested. | [optional] 
**Description** | **String** | The same rules in prose, for a client reading this at runtime. | [optional] 

## Examples

- Prepare the resource
```powershell
$Status200ResponsePaging = Initialize-FogApiStatus200ResponsePaging  -MaxRows null `
 -ExpandMaxItems null `
 -Description null
```

- Convert the resource to JSON
```powershell
$Status200ResponsePaging | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

