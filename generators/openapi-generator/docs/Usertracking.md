# Usertracking
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**Username** | **String** |  | 
**Action** | **String** |  | [optional] 
**Description** | **String** |  | [optional] 
**Date** | **System.DateTime** |  | [optional] 
**Anon3** | **String** |  | [optional] 
**Ip** | **String** |  | [optional] 
**SubjectLabel** | **String** |  | [optional] 
**VarHost** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Hostname** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 

## Examples

- Prepare the resource
```powershell
$Usertracking = Initialize-FogApiUsertracking  -Id null `
 -HostID null `
 -Username null `
 -Action null `
 -Description null `
 -Date null `
 -Anon3 null `
 -Ip null `
 -SubjectLabel null `
 -VarHost null `
 -Hostname null
```

- Convert the resource to JSON
```powershell
$Usertracking | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

