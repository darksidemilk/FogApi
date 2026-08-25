# Taskstate
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Description** | **String** |  | [optional] 
**Order** | **Int32** |  | [optional] [default to 0]
**Icon** | **String** |  | [optional] 

## Examples

- Prepare the resource
```powershell
$Taskstate = Initialize-FogApiTaskstate  -Id null `
 -Name null `
 -Description null `
 -Order null `
 -Icon null
```

- Convert the resource to JSON
```powershell
$Taskstate | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

