# Hostautologout
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**Time** | **String** |  | 

## Examples

- Prepare the resource
```powershell
$Hostautologout = Initialize-FogApiHostautologout  -Id null `
 -HostID null `
 -Time null
```

- Convert the resource to JSON
```powershell
$Hostautologout | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

