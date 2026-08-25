# Tasklog
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**TaskID** | **Int32** |  | [optional] 
**StateID** | **Int32** |  | [optional] 
**Ip** | **String** |  | [optional] 
**Type** | **String** |  | [optional] [default to "state"]
**Text** | **String** |  | [optional] 
**HostID** | **Int32** |  | [optional] 
**HostName** | **String** |  | [optional] 
**TaskTypeName** | **String** |  | [optional] 
**ImageName** | **String** |  | [optional] 

## Examples

- Prepare the resource
```powershell
$Tasklog = Initialize-FogApiTasklog  -Id null `
 -TaskID null `
 -StateID null `
 -Ip null `
 -Type null `
 -Text null `
 -HostID null `
 -HostName null `
 -TaskTypeName null `
 -ImageName null
```

- Convert the resource to JSON
```powershell
$Tasklog | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

