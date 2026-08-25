# Ldapgroup
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **String** | No type information available for this column. | [optional] [readonly] 
**ServerID** | **String** | No type information available for this column. | 
**Name** | **String** | No type information available for this column. | 
**Roles** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Usergroups** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Ldapserver** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 

## Examples

- Prepare the resource
```powershell
$Ldapgroup = Initialize-FogApiLdapgroup  -Id null `
 -ServerID null `
 -Name null `
 -Roles null `
 -Usergroups null `
 -Ldapserver null
```

- Convert the resource to JSON
```powershell
$Ldapgroup | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

