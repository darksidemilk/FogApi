# Printer
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Description** | **String** |  | [optional] 
**Port** | **String** |  | [optional] 
**File** | **String** |  | [optional] 
**Model** | **String** |  | [optional] 
**Config** | **String** |  | [optional] 
**ConfigFile** | **String** |  | [optional] 
**Ip** | **String** |  | [optional] 
**PAnon2** | **String** |  | [optional] 
**PAnon3** | **String** |  | [optional] 
**PAnon4** | **String** |  | [optional] 
**PAnon5** | **String** |  | [optional] 

## Examples

- Prepare the resource
```powershell
$Printer = Initialize-FogApiPrinter  -Id null `
 -Name null `
 -Description null `
 -Port null `
 -File null `
 -Model null `
 -Config null `
 -ConfigFile null `
 -Ip null `
 -PAnon2 null `
 -PAnon3 null `
 -PAnon4 null `
 -PAnon5 null
```

- Convert the resource to JSON
```powershell
$Printer | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

