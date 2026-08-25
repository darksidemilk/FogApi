# Tasktype
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

## Examples

- Prepare the resource
```powershell
$Tasktype = Initialize-FogApiTasktype  -Id null `
 -Name null `
 -Description null `
 -Icon null `
 -Kernel null `
 -KernelArgs null `
 -Type null `
 -IsAdvanced null `
 -Access null `
 -Initrd null
```

- Convert the resource to JSON
```powershell
$Tasktype | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

