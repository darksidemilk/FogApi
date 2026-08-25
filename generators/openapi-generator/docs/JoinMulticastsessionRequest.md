# JoinMulticastsessionRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | [optional] 
**Port** | **Int32** |  | [optional] [default to 0]
**Logpath** | **String** |  | [optional] 
**Image** | **String** |  | [optional] 
**Clients** | **Int32** |  | [optional] [default to 0]
**Sessclients** | **Int32** |  | [optional] [default to 0]
**Interface** | **String** |  | [optional] 
**Starttime** | **System.DateTime** |  | [optional] 
**Percent** | **Int32** |  | [optional] [default to 0]
**StateID** | **Int32** |  | [optional] [default to 0]
**Completetime** | **System.DateTime** |  | [optional] 
**IsDD** | **Int32** |  | [optional] [default to 0]
**StoragegroupID** | **Int32** |  | [optional] 
**Shutdown** | **String** |  | [optional] [default to "0"]
**Maxwait** | **Int32** |  | [optional] [default to 0]
**Senderpid** | **Int32** |  | [optional] [default to 0]
**Sendernode** | **Int32** |  | [optional] [default to 0]
**Senderstart** | **System.DateTime** |  | [optional] 
**Anon5** | **String** |  | [optional] 
**Imagename** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**State** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinMulticastsessionRequest = Initialize-FogApiJoinMulticastsessionRequest  -Id null `
 -Name null `
 -Port null `
 -Logpath null `
 -Image null `
 -Clients null `
 -Sessclients null `
 -Interface null `
 -Starttime null `
 -Percent null `
 -StateID null `
 -Completetime null `
 -IsDD null `
 -StoragegroupID null `
 -Shutdown null `
 -Maxwait null `
 -Senderpid null `
 -Sendernode null `
 -Senderstart null `
 -Anon5 null `
 -Imagename null `
 -State null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinMulticastsessionRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

