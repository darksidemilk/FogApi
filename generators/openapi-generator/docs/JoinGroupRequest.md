# JoinGroupRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Description** | **String** |  | [optional] 
**Building** | **Int32** |  | [optional] [default to 0]
**Kernel** | **String** |  | [optional] 
**KernelArgs** | **String** |  | [optional] 
**KernelDevice** | **String** |  | [optional] 
**Init** | **String** |  | [optional] 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinGroupRequest = Initialize-FogApiJoinGroupRequest  -Id null `
 -Name null `
 -Description null `
 -Building null `
 -Kernel null `
 -KernelArgs null `
 -KernelDevice null `
 -Init null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinGroupRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

