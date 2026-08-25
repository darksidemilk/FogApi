# Whoami200Response
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**NETFogServerIp** | **String** | This server&#39;s own IP address. Space-separated when the interface carries more than one. | [optional] 
**NETHostname** | **String** | This server&#39;s hostname, as its certificate names it. | [optional] 
**FOGOsId** | **String** | Numeric OS family id the installer recorded. A second encoding of FOG_os_name whose meaning has changed between releases; prefer FOG_os_name. | [optional] 
**FOGOsName** | **String** | OS family name the installer recorded. The stable identifier of the two. | [optional] 
**FOGInstallType** | **String** | N for a full server, S for a storage node. | [optional] 

## Examples

- Prepare the resource
```powershell
$Whoami200Response = Initialize-FogApiWhoami200Response  -NETFogServerIp null `
 -NETHostname null `
 -FOGOsId null `
 -FOGOsName null `
 -FOGInstallType null
```

- Convert the resource to JSON
```powershell
$Whoami200Response | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

