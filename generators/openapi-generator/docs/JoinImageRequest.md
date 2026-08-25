# JoinImageRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | 
**Description** | **String** |  | [optional] 
**Path** | **String** |  | 
**Building** | **Int32** |  | [optional] [default to 0]
**Size** | **String** |  | [optional] 
**ImageTypeID** | **Int32** |  | 
**ImagePartitionTypeID** | **Int32** |  | [optional] 
**OsID** | **Int32** |  | 
**Deployed** | **System.DateTime** |  | [optional] 
**Format** | **String** |  | [optional] 
**Magnet** | **String** |  | [optional] 
**Protected** | **Int32** |  | [optional] [default to 0]
**Compress** | **Int32** |  | [optional] 
**IsEnabled** | **String** |  | [optional] [default to "1"]
**ToReplicate** | **String** |  | [optional] [default to "1"]
**Srvsize** | **Int32** |  | [optional] [default to 0]
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinImageRequest = Initialize-FogApiJoinImageRequest  -Id null `
 -Name null `
 -Description null `
 -Path null `
 -Building null `
 -Size null `
 -ImageTypeID null `
 -ImagePartitionTypeID null `
 -OsID null `
 -Deployed null `
 -Format null `
 -Magnet null `
 -Protected null `
 -Compress null `
 -IsEnabled null `
 -ToReplicate null `
 -Srvsize null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinImageRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

