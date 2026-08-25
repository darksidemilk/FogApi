# JoinTasktypeRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Description** | **String** |  | [optional] 
**Icon** | **String** |  | 
**Kernel** | **String** |  | [optional] 
**KernelArgs** | **String** |  | [optional] 
**Type** | **String** |  | [optional] [default to "user"]
**IsAdvanced** | **String** |  | [optional] [default to "0"]
**Access** | **String** |  | [optional] [default to "both"]
**Initrd** | **String** |  | [optional] 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinTasktypeRequest = Initialize-FogApiJoinTasktypeRequest  -Id null `
 -Name null `
 -Description null `
 -Icon null `
 -Kernel null `
 -KernelArgs null `
 -Type null `
 -IsAdvanced null `
 -Access null `
 -Initrd null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinTasktypeRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

