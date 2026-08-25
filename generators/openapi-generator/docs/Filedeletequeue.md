# Filedeletequeue
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Path** | **String** |  | 
**StoragegroupID** | **Int32** |  | 
**CompletedTime** | **System.DateTime** |  | [optional] 
**StateID** | **Int32** |  | [optional] [default to 0]
**Pathtype** | **String** |  | 

## Examples

- Prepare the resource
```powershell
$Filedeletequeue = Initialize-FogApiFiledeletequeue  -Id null `
 -Path null `
 -StoragegroupID null `
 -CompletedTime null `
 -StateID null `
 -Pathtype null
```

- Convert the resource to JSON
```powershell
$Filedeletequeue | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

