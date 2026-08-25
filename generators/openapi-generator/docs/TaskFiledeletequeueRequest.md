# TaskFiledeletequeueRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**TaskTypeID** | [**TaskFiledeletequeueRequestTaskTypeID**](TaskFiledeletequeueRequestTaskTypeID.md) |  | [optional] 
**TaskName** | **String** |  | [optional] 
**Shutdown** | [**TaskFiledeletequeueRequestShutdown**](TaskFiledeletequeueRequestShutdown.md) |  | [optional] 
**Debug** | [**TaskFiledeletequeueRequestShutdown**](TaskFiledeletequeueRequestShutdown.md) |  | [optional] 
**DeploySnapins** | [**TaskFiledeletequeueRequestDeploySnapins**](TaskFiledeletequeueRequestDeploySnapins.md) |  | [optional] 
**Passreset** | **String** |  | [optional] 
**Sessionjoin** | [**TaskFiledeletequeueRequestShutdown**](TaskFiledeletequeueRequestShutdown.md) |  | [optional] 
**Wol** | [**TaskFiledeletequeueRequestShutdown**](TaskFiledeletequeueRequestShutdown.md) |  | [optional] 

## Examples

- Prepare the resource
```powershell
$TaskFiledeletequeueRequest = Initialize-FogApiTaskFiledeletequeueRequest  -TaskTypeID null `
 -TaskName null `
 -Shutdown null `
 -Debug null `
 -DeploySnapins null `
 -Passreset null `
 -Sessionjoin null `
 -Wol null
```

- Convert the resource to JSON
```powershell
$TaskFiledeletequeueRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

