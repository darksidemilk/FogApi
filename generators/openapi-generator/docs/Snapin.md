# Snapin
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Description** | **String** |  | [optional] 
**File** | **String** |  | 
**VarArgs** | **String** |  | [optional] 
**Reboot** | **String** |  | [optional] 
**Shutdown** | **String** |  | [optional] [default to "0"]
**RunWith** | **String** |  | [optional] 
**RunWithArgs** | **String** |  | [optional] 
**Protected** | **Int32** |  | [optional] [default to 0]
**IsEnabled** | **String** |  | [optional] [default to "1"]
**ToReplicate** | **String** |  | [optional] [default to "1"]
**Hide** | **String** |  | [optional] [default to "0"]
**Timeout** | **Int32** |  | [optional] [default to 0]
**Packtype** | **String** |  | [optional] [default to "0"]
**Hash** | **String** |  | [optional] 
**Size** | **Int32** |  | [optional] [default to 0]
**Anon3** | **String** |  | [optional] 
**Hosts** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Storagegroups** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Path** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 

## Examples

- Prepare the resource
```powershell
$Snapin = Initialize-FogApiSnapin  -Id null `
 -Name null `
 -Description null `
 -File null `
 -VarArgs null `
 -Reboot null `
 -Shutdown null `
 -RunWith null `
 -RunWithArgs null `
 -Protected null `
 -IsEnabled null `
 -ToReplicate null `
 -Hide null `
 -Timeout null `
 -Packtype null `
 -Hash null `
 -Size null `
 -Anon3 null `
 -Hosts null `
 -Storagegroups null `
 -Path null
```

- Convert the resource to JSON
```powershell
$Snapin | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

