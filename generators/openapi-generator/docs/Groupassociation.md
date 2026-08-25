# Groupassociation
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**GroupID** | **Int32** |  | 

## Examples

- Prepare the resource
```powershell
$Groupassociation = Initialize-FogApiGroupassociation  -Id null `
 -HostID null `
 -GroupID null
```

- Convert the resource to JSON
```powershell
$Groupassociation | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

