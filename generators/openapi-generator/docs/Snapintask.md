# Snapintask
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**JobID** | **Int32** |  | 
**StateID** | **Int32** |  | [optional] [default to 0]
**Checkin** | **System.DateTime** |  | [optional] 
**Complete** | **System.DateTime** |  | [optional] 
**SnapinID** | **Int32** |  | 
**Sequence** | **Int32** |  | [optional] [default to 0]
**VarReturn** | **Int32** |  | [optional] [default to 0]
**Details** | **String** |  | [optional] 
**Snapin** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**State** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Snapinjob** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 

## Examples

- Prepare the resource
```powershell
$Snapintask = Initialize-FogApiSnapintask  -Id null `
 -JobID null `
 -StateID null `
 -Checkin null `
 -Complete null `
 -SnapinID null `
 -Sequence null `
 -VarReturn null `
 -Details null `
 -Snapin null `
 -State null `
 -Snapinjob null
```

- Convert the resource to JSON
```powershell
$Snapintask | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

