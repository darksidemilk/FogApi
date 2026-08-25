# JoinPxemenuoptionsRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Description** | **String** |  | [optional] 
**Params** | **String** |  | [optional] 
**Default** | **Int32** |  | [optional] [default to 0]
**RegMenu** | **Int32** |  | [optional] [default to 0]
**VarArgs** | **String** |  | [optional] 
**Hotkey** | **String** |  | [optional] [default to "0"]
**Keysequence** | **String** |  | [optional] 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinPxemenuoptionsRequest = Initialize-FogApiJoinPxemenuoptionsRequest  -Id null `
 -Name null `
 -Description null `
 -Params null `
 -Default null `
 -RegMenu null `
 -VarArgs null `
 -Hotkey null `
 -Keysequence null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinPxemenuoptionsRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

