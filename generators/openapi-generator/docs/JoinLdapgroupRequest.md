# JoinLdapgroupRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **String** | No type information available for this column. | [optional] [readonly] 
**ServerID** | **String** | No type information available for this column. | 
**Name** | **String** | No type information available for this column. | 
**Roles** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Usergroups** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Ldapserver** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinLdapgroupRequest = Initialize-FogApiJoinLdapgroupRequest  -Id null `
 -ServerID null `
 -Name null `
 -Roles null `
 -Usergroups null `
 -Ldapserver null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinLdapgroupRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

