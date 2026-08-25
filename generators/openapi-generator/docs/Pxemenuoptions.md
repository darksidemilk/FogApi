# Pxemenuoptions
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

## Examples

- Prepare the resource
```powershell
$Pxemenuoptions = Initialize-FogApiPxemenuoptions  -Id null `
 -Name null `
 -Description null `
 -Params null `
 -Default null `
 -RegMenu null `
 -VarArgs null `
 -Hotkey null `
 -Keysequence null
```

- Convert the resource to JSON
```powershell
$Pxemenuoptions | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

