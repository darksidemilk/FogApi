# Storagenode
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | [optional] 
**Description** | **String** |  | [optional] 
**IsMaster** | **String** |  | [optional] 
**StoragegroupID** | **Int32** |  | [optional] 
**IsEnabled** | **String** |  | [optional] 
**IsGraphEnabled** | **String** |  | [optional] [default to "1"]
**Path** | **String** |  | 
**Ftppath** | **String** |  | 
**Bitrate** | **String** |  | [optional] 
**HelloInterval** | **String** |  | [optional] 
**Snapinpath** | **String** |  | [optional] 
**Sslpath** | **String** |  | [optional] 
**Ip** | **String** |  | 
**MaxClients** | **Int32** |  | [optional] [default to 0]
**User** | **String** |  | 
**Pass** | **String** | Never returned by the API. | [readonly] 
**Key** | **String** | Never returned by the API. | [optional] [readonly] 
**Interface** | **String** |  | [optional] 
**Bandwidth** | **Int32** |  | [optional] [default to 0]
**Webroot** | **String** |  | [optional] 
**Graphcolor** | **String** |  | [optional] 

## Examples

- Prepare the resource
```powershell
$Storagenode = Initialize-FogApiStoragenode  -Id null `
 -Name null `
 -Description null `
 -IsMaster null `
 -StoragegroupID null `
 -IsEnabled null `
 -IsGraphEnabled null `
 -Path null `
 -Ftppath null `
 -Bitrate null `
 -HelloInterval null `
 -Snapinpath null `
 -Sslpath null `
 -Ip null `
 -MaxClients null `
 -User null `
 -Pass null `
 -Key null `
 -Interface null `
 -Bandwidth null `
 -Webroot null `
 -Graphcolor null
```

- Convert the resource to JSON
```powershell
$Storagenode | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

