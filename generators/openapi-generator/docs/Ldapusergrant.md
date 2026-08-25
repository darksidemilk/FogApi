# Ldapusergrant
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **String** | No type information available for this column. | [optional] [readonly] 
**Name** | **String** | No type information available for this column. | [optional] 
**UserID** | **String** | No type information available for this column. | 
**TargetType** | **String** | No type information available for this column. | 
**TargetID** | **String** | No type information available for this column. | 

## Examples

- Prepare the resource
```powershell
$Ldapusergrant = Initialize-FogApiLdapusergrant  -Id null `
 -Name null `
 -UserID null `
 -TargetType null `
 -TargetID null
```

- Convert the resource to JSON
```powershell
$Ldapusergrant | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

