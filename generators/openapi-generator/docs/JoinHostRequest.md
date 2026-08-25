# JoinHostRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** | Enforced by Host::isHostnameSafe(), which is stricter than the column: at most 15 characters, and only letters, digits, underscore and ! @ # $ % ^ ( ) - &#39; { } . ~ A name that fails this is refused by Host::save() with a 406. | 
**Description** | **String** |  | [optional] 
**Ip** | **String** |  | [optional] 
**ImageID** | **Int32** |  | [optional] [default to 0]
**Building** | **Int32** |  | [optional] [default to 0]
**Deployed** | **System.DateTime** |  | [optional] 
**UseAD** | **String** |  | [optional] 
**ADDomain** | **String** |  | [optional] 
**ADOU** | **String** |  | [optional] 
**ADUser** | **String** |  | [optional] 
**ADPass** | **String** | Omitted from list responses; returned only on a single GET by id. | [optional] 
**ADPassLegacy** | **String** | Omitted from list responses; returned only on a single GET by id. | [optional] 
**ProductKey** | **String** | Omitted from list responses; returned only on a single GET by id. | [optional] 
**PrinterLevel** | **String** |  | [optional] 
**KernelArgs** | **String** |  | [optional] 
**Kernel** | **String** |  | [optional] 
**KernelDevice** | **String** |  | [optional] 
**Init** | **String** |  | [optional] 
**Pending** | **String** |  | [optional] [default to "0"]
**PubKey** | **String** | Maintained by the server. It may be sent back unchanged, but a request that would change it is refused. | [optional] [readonly] 
**SecTok** | **String** | Maintained by the server. It may be sent back unchanged, but a request that would change it is refused. | [optional] [readonly] 
**PrevSecTok** | **String** | Maintained by the server. It may be sent back unchanged, but a request that would change it is refused. | [optional] [readonly] 
**SecTime** | **System.DateTime** | Maintained by the server. It may be sent back unchanged, but a request that would change it is refused. | [optional] [readonly] 
**Pingstatus** | **String** |  | [optional] 
**Pingmethod** | **String** |  | [optional] 
**Lastping** | **System.DateTime** |  | [optional] 
**Lastcheckin** | **System.DateTime** |  | [optional] 
**Biosexit** | **String** |  | [optional] 
**Efiexit** | **String** |  | [optional] 
**Enforce** | **String** |  | [optional] [default to "1"]
**Token** | **String** | Maintained by the server. It may be sent back unchanged, but a request that would change it is refused. | [optional] [readonly] 
**Tokenlock** | **Int32** |  | [optional] [default to 0]
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinHostRequest = Initialize-FogApiJoinHostRequest  -Id null `
 -Name null `
 -Description null `
 -Ip null `
 -ImageID null `
 -Building null `
 -Deployed null `
 -UseAD null `
 -ADDomain null `
 -ADOU null `
 -ADUser null `
 -ADPass null `
 -ADPassLegacy null `
 -ProductKey null `
 -PrinterLevel null `
 -KernelArgs null `
 -Kernel null `
 -KernelDevice null `
 -Init null `
 -Pending null `
 -PubKey null `
 -SecTok null `
 -PrevSecTok null `
 -SecTime null `
 -Pingstatus null `
 -Pingmethod null `
 -Lastping null `
 -Lastcheckin null `
 -Biosexit null `
 -Efiexit null `
 -Enforce null `
 -Token null `
 -Tokenlock null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinHostRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

