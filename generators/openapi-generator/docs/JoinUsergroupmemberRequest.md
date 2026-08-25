# JoinUsergroupmemberRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | [optional] 
**UsergroupID** | **Int32** |  | 
**UserID** | **Int32** |  | 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinUsergroupmemberRequest = Initialize-FogApiJoinUsergroupmemberRequest  -Id null `
 -Name null `
 -UsergroupID null `
 -UserID null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinUsergroupmemberRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

