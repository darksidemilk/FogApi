# JoinLdapgrouproleassociationRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **String** | No type information available for this column. | [optional] [readonly] 
**Name** | **String** | No type information available for this column. | [optional] 
**LdapgroupID** | **String** | No type information available for this column. | 
**RoleID** | **String** | No type information available for this column. | 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinLdapgrouproleassociationRequest = Initialize-FogApiJoinLdapgrouproleassociationRequest  -Id null `
 -Name null `
 -LdapgroupID null `
 -RoleID null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinLdapgrouproleassociationRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

