# JoinSettingRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Description** | **String** |  | [optional] 
**Value** | **String** |  | [optional] 
**Category** | **String** |  | [optional] 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinSettingRequest = Initialize-FogApiJoinSettingRequest  -Id null `
 -Name null `
 -Description null `
 -Value null `
 -Category null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinSettingRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

