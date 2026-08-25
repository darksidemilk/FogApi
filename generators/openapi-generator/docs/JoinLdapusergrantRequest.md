# JoinLdapusergrantRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **String** | No type information available for this column. | [optional] [readonly] 
**Name** | **String** | No type information available for this column. | [optional] 
**UserID** | **String** | No type information available for this column. | 
**TargetType** | **String** | No type information available for this column. | 
**TargetID** | **String** | No type information available for this column. | 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinLdapusergrantRequest = Initialize-FogApiJoinLdapusergrantRequest  -Id null `
 -Name null `
 -UserID null `
 -TargetType null `
 -TargetID null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinLdapusergrantRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

