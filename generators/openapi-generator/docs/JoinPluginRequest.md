# JoinPluginRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**State** | **String** |  | [optional] 
**Installed** | **String** |  | [optional] 
**Version** | **String** |  | [optional] 
**Icon** | **String** |  | [optional] 
**Runfile** | **String** |  | [optional] 
**Location** | **String** |  | [optional] 
**Description** | **String** |  | [optional] 
**Schema** | **Int32** |  | [optional] [default to 0]
**PAnon5** | **String** |  | [optional] 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinPluginRequest = Initialize-FogApiJoinPluginRequest  -Id null `
 -Name null `
 -State null `
 -Installed null `
 -Version null `
 -Icon null `
 -Runfile null `
 -Location null `
 -Description null `
 -Schema null `
 -PAnon5 null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinPluginRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

