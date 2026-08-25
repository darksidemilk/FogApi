# Setting
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Description** | **String** |  | [optional] 
**Value** | **String** |  | [optional] 
**Category** | **String** |  | [optional] 

## Examples

- Prepare the resource
```powershell
$Setting = Initialize-FogApiSetting  -Id null `
 -Name null `
 -Description null `
 -Value null `
 -Category null
```

- Convert the resource to JSON
```powershell
$Setting | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

