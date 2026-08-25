# Snapinassociation
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**SnapinID** | **Int32** |  | 
**Sequence** | **Int32** |  | [optional] [default to 0]

## Examples

- Prepare the resource
```powershell
$Snapinassociation = Initialize-FogApiSnapinassociation  -Id null `
 -HostID null `
 -SnapinID null `
 -Sequence null
```

- Convert the resource to JSON
```powershell
$Snapinassociation | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

