# Printerassociation
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**PrinterID** | **Int32** |  | 
**IsDefault** | **String** |  | [optional] 
**Anon1** | **String** |  | [optional] 
**Anon2** | **String** |  | [optional] 
**Anon3** | **String** |  | [optional] 
**Anon4** | **String** |  | [optional] 
**Anon5** | **String** |  | [optional] 

## Examples

- Prepare the resource
```powershell
$Printerassociation = Initialize-FogApiPrinterassociation  -Id null `
 -HostID null `
 -PrinterID null `
 -IsDefault null `
 -Anon1 null `
 -Anon2 null `
 -Anon3 null `
 -Anon4 null `
 -Anon5 null
```

- Convert the resource to JSON
```powershell
$Printerassociation | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

