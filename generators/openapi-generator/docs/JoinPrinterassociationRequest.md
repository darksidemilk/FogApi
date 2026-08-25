# JoinPrinterassociationRequest
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
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinPrinterassociationRequest = Initialize-FogApiJoinPrinterassociationRequest  -Id null `
 -HostID null `
 -PrinterID null `
 -IsDefault null `
 -Anon1 null `
 -Anon2 null `
 -Anon3 null `
 -Anon4 null `
 -Anon5 null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinPrinterassociationRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

