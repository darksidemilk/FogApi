# Ldap
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **String** | No type information available for this column. | [optional] [readonly] 
**Name** | **String** | No type information available for this column. | 
**Description** | **String** | No type information available for this column. | [optional] 
**Address** | **String** | No type information available for this column. | 
**Port** | **String** | No type information available for this column. | 
**SearchDN** | **String** | No type information available for this column. | 
**UserNamAttr** | **String** | No type information available for this column. | [optional] 
**GrpNamAttr** | **String** | No type information available for this column. | [optional] 
**GrpMemberAttr** | **String** | No type information available for this column. | [optional] 
**SearchScope** | **String** | No type information available for this column. | 
**BindDN** | **String** | No type information available for this column. | [optional] 
**BindPwd** | **String** | No type information available for this column. | [optional] 
**GrpSearchDN** | **String** | No type information available for this column. | [optional] 
**UseGroupMatch** | **String** | No type information available for this column. | 
**DisplayNameOn** | **String** | No type information available for this column. | [optional] 
**DisplayNameAttr** | **String** | No type information available for this column. | [optional] 
**IsLdaps** | **String** | No type information available for this column. | [optional] 
**Allowapi** | **String** | No type information available for this column. | [optional] 
**NestedGroups** | **String** | No type information available for this column. | [optional] 
**NestedDepth** | **String** | No type information available for this column. | [optional] 
**TlsVerify** | **String** | No type information available for this column. | [optional] 
**TlsCaCert** | **String** | No type information available for this column. | [optional] 

## Examples

- Prepare the resource
```powershell
$Ldap = Initialize-FogApiLdap  -Id null `
 -Name null `
 -Description null `
 -Address null `
 -Port null `
 -SearchDN null `
 -UserNamAttr null `
 -GrpNamAttr null `
 -GrpMemberAttr null `
 -SearchScope null `
 -BindDN null `
 -BindPwd null `
 -GrpSearchDN null `
 -UseGroupMatch null `
 -DisplayNameOn null `
 -DisplayNameAttr null `
 -IsLdaps null `
 -Allowapi null `
 -NestedGroups null `
 -NestedDepth null `
 -TlsVerify null `
 -TlsCaCert null
```

- Convert the resource to JSON
```powershell
$Ldap | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

