# Hostscreensetting
## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Id** | **Int32** |  | [optional] [readonly] 
**HostID** | **Int32** |  | 
**Width** | **Int32** |  | [optional] [default to 0]
**Height** | **Int32** |  | [optional] [default to 0]
**Refresh** | **Int32** |  | [optional] [default to 0]
**Orientation** | **Int32** |  | [optional] [default to 0]
**Other1** | **Int32** |  | [optional] [default to 0]
**Other2** | **Int32** |  | [optional] [default to 0]

## Examples

- Prepare the resource
```powershell
$Hostscreensetting = Initialize-FogApiHostscreensetting  -Id null `
 -HostID null `
 -Width null `
 -Height null `
 -Refresh null `
 -Orientation null `
 -Other1 null `
 -Other2 null
```

- Convert the resource to JSON
```powershell
$Hostscreensetting | ConvertTo-JSON
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

