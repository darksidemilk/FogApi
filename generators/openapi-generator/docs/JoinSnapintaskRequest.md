# JoinSnapintaskRequest
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
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinSnapintaskRequest = Initialize-FogApiJoinSnapintaskRequest  -Id null `
 -JobID null `
 -StateID null `
 -Checkin null `
 -Complete null `
 -SnapinID null `
 -Sequence null `
 -VarReturn null `
 -Details null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinSnapintaskRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

