# JoinHostscreensettingRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**Width** | **Int32** |  | [optional] [default to 0]
**Height** | **Int32** |  | [optional] [default to 0]
**Refresh** | **Int32** |  | [optional] [default to 0]
**Orientation** | **Int32** |  | [optional] [default to 0]
**Other1** | **Int32** |  | [optional] [default to 0]
**Other2** | **Int32** |  | [optional] [default to 0]
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinHostscreensettingRequest = Initialize-FogApiJoinHostscreensettingRequest  -Id null `
 -HostID null `
 -Width null `
 -Height null `
 -Refresh null `
 -Orientation null `
 -Other1 null `
 -Other2 null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinHostscreensettingRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

