# JoinLdapgroupusergroupassociationRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **String** | No type information available for this column. | [optional] [readonly] 
**Name** | **String** | No type information available for this column. | [optional] 
**LdapgroupID** | **String** | No type information available for this column. | 
**UsergroupID** | **String** | No type information available for this column. | 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinLdapgroupusergroupassociationRequest = Initialize-FogApiJoinLdapgroupusergroupassociationRequest  -Id null `
 -Name null `
 -LdapgroupID null `
 -UsergroupID null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinLdapgroupusergroupassociationRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

