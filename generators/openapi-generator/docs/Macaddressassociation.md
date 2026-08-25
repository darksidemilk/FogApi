# Macaddressassociation
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**Mac** | **String** |  | 
**Description** | **String** |  | [optional] 
**Pending** | **String** |  | [optional] [default to "0"]
**Primary** | **String** |  | [optional] [default to "0"]
**ClientIgnore** | **String** |  | [optional] [default to "0"]
**ImageIgnore** | **String** |  | [optional] [default to "0"]

## Examples

- Prepare the resource
```powershell
$Macaddressassociation = Initialize-FogApiMacaddressassociation  -Id null `
 -HostID null `
 -Mac null `
 -Description null `
 -Pending null `
 -Primary null `
 -ClientIgnore null `
 -ImageIgnore null
```

- Convert the resource to JSON
```powershell
$Macaddressassociation | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

