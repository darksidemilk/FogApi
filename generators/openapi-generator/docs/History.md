# History
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Info** | **String** |  | 
**Ip** | **String** |  | [optional] 
**Type** | **String** |  | [optional] 
**SubjectType** | **String** |  | [optional] 
**SubjectID** | **Int32** |  | [optional] 
**SubjectLabel** | **String** |  | [optional] 

## Examples

- Prepare the resource
```powershell
$History = Initialize-FogApiHistory  -Id null `
 -Info null `
 -Ip null `
 -Type null `
 -SubjectType null `
 -SubjectID null `
 -SubjectLabel null
```

- Convert the resource to JSON
```powershell
$History | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

