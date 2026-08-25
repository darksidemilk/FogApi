# JoinTaskRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [readonly] 
**Name** | **String** |  | [optional] 
**CheckInTime** | **System.DateTime** |  | [optional] 
**HostID** | **Int32** |  | 
**StateID** | **Int32** |  | [optional] 
**IsForced** | **String** |  | [optional] 
**ScheduledStartTime** | **System.DateTime** |  | [optional] 
**TypeID** | **Int32** |  | 
**Pct** | **Int32** | Maintained by the server. It may be sent back unchanged, but a request that would change it is refused. | [optional] [readonly] [default to 0]
**Bpm** | **String** | Maintained by the server. It may be sent back unchanged, but a request that would change it is refused. | [optional] [readonly] 
**TimeElapsed** | **String** | Maintained by the server. It may be sent back unchanged, but a request that would change it is refused. | [optional] [readonly] 
**TimeRemaining** | **String** | Maintained by the server. It may be sent back unchanged, but a request that would change it is refused. | [optional] [readonly] 
**DataCopied** | **String** | Maintained by the server. It may be sent back unchanged, but a request that would change it is refused. | [optional] [readonly] 
**Percent** | **String** | Maintained by the server. It may be sent back unchanged, but a request that would change it is refused. | [optional] [readonly] 
**DataTotal** | **String** | Maintained by the server. It may be sent back unchanged, but a request that would change it is refused. | [optional] [readonly] 
**StoragegroupID** | **Int32** |  | [optional] 
**StoragenodeID** | **Int32** |  | [optional] 
**NFSFailures** | **String** |  | [optional] 
**NFSLastMemberID** | **Int32** |  | [optional] 
**Shutdown** | **String** |  | [optional] 
**Passreset** | **String** |  | [optional] 
**IsDebug** | **Int32** |  | [optional] [default to 0]
**ImageID** | **Int32** |  | [optional] 
**Wol** | **String** |  | [optional] [default to "0"]
**Bypassbitlocker** | **String** |  | [optional] [default to "0"]
**StateChangedTime** | **System.DateTime** |  | [optional] 
**Image** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**VarHost** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Type** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**State** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Storagenode** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Storagegroup** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinTaskRequest = Initialize-FogApiJoinTaskRequest  -Id null `
 -Name null `
 -CheckInTime null `
 -HostID null `
 -StateID null `
 -IsForced null `
 -ScheduledStartTime null `
 -TypeID null `
 -Pct null `
 -Bpm null `
 -TimeElapsed null `
 -TimeRemaining null `
 -DataCopied null `
 -Percent null `
 -DataTotal null `
 -StoragegroupID null `
 -StoragenodeID null `
 -NFSFailures null `
 -NFSLastMemberID null `
 -Shutdown null `
 -Passreset null `
 -IsDebug null `
 -ImageID null `
 -Wol null `
 -Bypassbitlocker null `
 -StateChangedTime null `
 -Image null `
 -VarHost null `
 -Type null `
 -State null `
 -Storagenode null `
 -Storagegroup null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinTaskRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

