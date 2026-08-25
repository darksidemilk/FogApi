# Group
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
**Hosts** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 

## Examples

- Prepare the resource
```powershell
$Group = Initialize-FogApiGroup  -Id null `
 -Name null `
 -Description null `
 -Building null `
 -Kernel null `
 -KernelArgs null `
 -KernelDevice null `
 -Init null `
 -Hosts null
```

- Convert the resource to JSON
```powershell
$Group | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

