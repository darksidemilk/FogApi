# Ldapgroupusergroupassociation
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **String** | No type information available for this column. | [optional] [readonly] 
**Name** | **String** | No type information available for this column. | [optional] 
**LdapgroupID** | **String** | No type information available for this column. | 
**UsergroupID** | **String** | No type information available for this column. | 

## Examples

- Prepare the resource
```powershell
$Ldapgroupusergroupassociation = Initialize-FogApiLdapgroupusergroupassociation  -Id null `
 -Name null `
 -LdapgroupID null `
 -UsergroupID null
```

- Convert the resource to JSON
```powershell
$Ldapgroupusergroupassociation | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

