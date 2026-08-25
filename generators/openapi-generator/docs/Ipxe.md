# Ipxe
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Product** | **String** |  | [optional] 
**Manufacturer** | **String** |  | [optional] 
**Mac** | **String** |  | [optional] 
**Success** | **String** |  | [optional] 
**Failure** | **String** |  | [optional] 
**File** | **String** |  | [optional] 
**Version** | **String** |  | [optional] 

## Examples

- Prepare the resource
```powershell
$Ipxe = Initialize-FogApiIpxe  -Id null `
 -Product null `
 -Manufacturer null `
 -Mac null `
 -Success null `
 -Failure null `
 -File null `
 -Version null
```

- Convert the resource to JSON
```powershell
$Ipxe | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

