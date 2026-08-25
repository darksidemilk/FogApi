# JoinScheduledtaskRequest
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**Name** | **String** |  | [optional] 
**Description** | **String** |  | [optional] 
**Type** | **String** |  | 
**TaskTypeID** | **Int32** |  | 
**Minute** | **String** |  | [optional] 
**Hour** | **String** |  | [optional] 
**DayOfMonth** | **String** |  | [optional] 
**Month** | **String** |  | [optional] 
**DayOfWeek** | **String** |  | [optional] 
**IsGroupTask** | **String** |  | [optional] [default to "0"]
**HostID** | **Int32** |  | 
**Shutdown** | **String** |  | [optional] 
**Other1** | **String** |  | [optional] 
**Other2** | **String** |  | [optional] 
**Other3** | **String** |  | [optional] 
**Other4** | **String** |  | [optional] 
**Other5** | **String** |  | [optional] 
**ScheduleTime** | **Int32** |  | [optional] [default to 0]
**IsActive** | **String** |  | [optional] [default to "1"]
**ImageID** | **Int32** |  | [optional] 
**Ids** | **Int32[]** | The objects to apply these values to. An empty or absent list matches nothing and edits nothing. | 

## Examples

- Prepare the resource
```powershell
$JoinScheduledtaskRequest = Initialize-FogApiJoinScheduledtaskRequest  -Id null `
 -Name null `
 -Description null `
 -Type null `
 -TaskTypeID null `
 -Minute null `
 -Hour null `
 -DayOfMonth null `
 -Month null `
 -DayOfWeek null `
 -IsGroupTask null `
 -HostID null `
 -Shutdown null `
 -Other1 null `
 -Other2 null `
 -Other3 null `
 -Other4 null `
 -Other5 null `
 -ScheduleTime null `
 -IsActive null `
 -ImageID null `
 -Ids null
```

- Convert the resource to JSON
```powershell
$JoinScheduledtaskRequest | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

