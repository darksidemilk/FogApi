# JoinByNameGroupRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Names** | **String[]** | Names to resolve. Each is created if no object already has it. | 

## Examples

- Prepare the resource
```powershell
$JoinByNameGroupRequest = Initialize-FogApiJoinByNameGroupRequest  -Names null
```

- Convert the resource to JSON
```powershell
$JoinByNameGroupRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

