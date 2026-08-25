# Ldapgrouproleassociation
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **String** | No type information available for this column. | [optional] [readonly] 
**Name** | **String** | No type information available for this column. | [optional] 
**LdapgroupID** | **String** | No type information available for this column. | 
**RoleID** | **String** | No type information available for this column. | 

## Examples

- Prepare the resource
```powershell
$Ldapgrouproleassociation = Initialize-FogApiLdapgrouproleassociation  -Id null `
 -Name null `
 -LdapgroupID null `
 -RoleID null
```

- Convert the resource to JSON
```powershell
$Ldapgrouproleassociation | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

