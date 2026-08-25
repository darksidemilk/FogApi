# JoinUserRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Password** | **String** | Never returned by the API. | [readonly] 
**Type** | **Int32** |  | [optional] [default to 0]
**Display** | **String** |  | [optional] 
**Api** | **String** |  | [optional] [default to "1"]
**Token** | **String** | Maintained by the server. It may be sent back unchanged, but a request that would change it is refused. | [optional] [readonly] 
**Authsource** | **String** |  | [optional] 
**Apionly** | **String** |  | [optional] [default to "0"]
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinUserRequest = Initialize-FogApiJoinUserRequest  -Id null `
 -Name null `
 -Password null `
 -Type null `
 -Display null `
 -Api null `
 -Token null `
 -Authsource null `
 -Apionly null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinUserRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

