# JoinInventoryRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**PrimaryUser** | **String** |  | [optional] 
**Other1** | **String** |  | [optional] 
**Other2** | **String** |  | [optional] 
**DeleteDate** | **System.DateTime** |  | [optional] 
**Sysman** | **String** |  | [optional] 
**Sysproduct** | **String** |  | [optional] 
**Sysversion** | **String** |  | [optional] 
**Sysserial** | **String** |  | [optional] 
**Sysuuid** | **String** |  | [optional] 
**Systype** | **String** |  | [optional] 
**Biosversion** | **String** |  | [optional] 
**Biosvendor** | **String** |  | [optional] 
**Biosdate** | **String** |  | [optional] 
**Mbman** | **String** |  | [optional] 
**Mbproductname** | **String** |  | [optional] 
**Mbversion** | **String** |  | [optional] 
**Mbserial** | **String** |  | [optional] 
**Mbasset** | **String** |  | [optional] 
**Cpuman** | **String** |  | [optional] 
**Cpuversion** | **String** |  | [optional] 
**Cpucurrent** | **String** |  | [optional] 
**Cpumax** | **String** |  | [optional] 
**Mem** | **String** |  | [optional] 
**Hdmodel** | **String** |  | [optional] 
**Hdserial** | **String** |  | [optional] 
**Hdfirmware** | **String** |  | [optional] 
**Caseman** | **String** |  | [optional] 
**Casever** | **String** |  | [optional] 
**Caseserial** | **String** |  | [optional] 
**Caseasset** | **String** |  | [optional] 
**Gpuvendors** | **String** |  | [optional] 
**Gpuproducts** | **String** |  | [optional] 
**VarHost** | [**AnyType**](.md) | Computed field. Returned by the API but not a column, and not settable. | [optional] [readonly] 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinInventoryRequest = Initialize-FogApiJoinInventoryRequest  -Id null `
 -HostID null `
 -PrimaryUser null `
 -Other1 null `
 -Other2 null `
 -DeleteDate null `
 -Sysman null `
 -Sysproduct null `
 -Sysversion null `
 -Sysserial null `
 -Sysuuid null `
 -Systype null `
 -Biosversion null `
 -Biosvendor null `
 -Biosdate null `
 -Mbman null `
 -Mbproductname null `
 -Mbversion null `
 -Mbserial null `
 -Mbasset null `
 -Cpuman null `
 -Cpuversion null `
 -Cpucurrent null `
 -Cpumax null `
 -Mem null `
 -Hdmodel null `
 -Hdserial null `
 -Hdfirmware null `
 -Caseman null `
 -Casever null `
 -Caseserial null `
 -Caseasset null `
 -Gpuvendors null `
 -Gpuproducts null `
 -VarHost null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinInventoryRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

