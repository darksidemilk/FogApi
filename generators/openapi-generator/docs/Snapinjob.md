# Snapinjob
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**StateID** | **Int32** |  | 
**AbortOnFail** | **String** |  | [optional] [default to "0"]

## Examples

- Prepare the resource
```powershell
$Snapinjob = Initialize-FogApiSnapinjob  -Id null `
 -HostID null `
 -StateID null `
 -AbortOnFail null
```

- Convert the resource to JSON
```powershell
$Snapinjob | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

