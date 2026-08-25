# FogApi.FogApi\Api.FogRolepermissionApi

All URIs are relative to *http://fog-dev/fog*

Method | HTTP request | Description
------------- | ------------- | -------------
[**Invoke-FogCountRolepermission**](FogRolepermissionApi.md#Invoke-FogCountRolepermission) | **GET** /rolepermission/count | Count rolepermission
[**New-FogRolepermission**](FogRolepermissionApi.md#New-FogRolepermission) | **POST** /rolepermission | Create a rolepermission
[**Invoke-FogDeleteRolepermission**](FogRolepermissionApi.md#Invoke-FogDeleteRolepermission) | **DELETE** /rolepermission/{id} | Delete a rolepermission
[**Invoke-FogIdsRolepermission**](FogRolepermissionApi.md#Invoke-FogIdsRolepermission) | **GET** /rolepermission/ids | Ids for rolepermission
[**ConvertTo-FogdivRolepermission**](FogRolepermissionApi.md#ConvertTo-FogdivRolepermission) | **GET** /rolepermission/{id} | Get one rolepermission by id
[**Join-FogRolepermission**](FogRolepermissionApi.md#Join-FogRolepermission) | **PUT** /rolepermission/join | Bulk edit rolepermission
[**Invoke-FogListRolepermission**](FogRolepermissionApi.md#Invoke-FogListRolepermission) | **GET** /rolepermission | List rolepermission
[**Move-FogsRolepermission**](FogRolepermissionApi.md#Move-FogsRolepermission) | **GET** /rolepermission/names | Id and name pairs for rolepermission
[**Search-FogRolepermission**](FogRolepermissionApi.md#Search-FogRolepermission) | **GET** /rolepermission/search/{item} | Search rolepermission
[**Update-FogRolepermission**](FogRolepermissionApi.md#Update-FogRolepermission) | **PUT** /rolepermission/{id} | Update a rolepermission


<a id="Invoke-FogCountRolepermission"></a>
# **Invoke-FogCountRolepermission**
> CountFiledeletequeue200Response Invoke-FogCountRolepermission<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Count rolepermission

Accepts the same optional filter as a list. Reports the true filtered total and ignores paging.

### Example
```powershell
# general setting of the PowerShell module, e.g. base URL, authentication, etc
$Configuration = Get-Configuration
# Configure HTTP basic authorization: basicAuth
$Configuration.Username = "YOUR_USERNAME"
$Configuration.Password = "YOUR_PASSWORD"

# Configure API key authorization: fogApiToken
$Configuration.ApiKey.fog-api-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-api-token = "Bearer"


# Configure API key authorization: fogUserToken
$Configuration.ApiKey.fog-user-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-user-token = "Bearer"

$Filter = "MyFilter" # String | Server-side column filter, written as a URL encoded query string: field=value, joined with & for more than one, ANDed together. A comma separated value matches any of its parts. Only fields the class declares are accepted -- anything else answers 400 and names the offending key -- and credential fields are refused outright. Also accepted as a trailing path segment (/{class}/list/field=value), which wins when both are sent. (optional)

# Count rolepermission
try {
    $Result = Invoke-FogCountRolepermission -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogCountRolepermission: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Filter** | **String**| Server-side column filter, written as a URL encoded query string: field&#x3D;value, joined with &amp; for more than one, ANDed together. A comma separated value matches any of its parts. Only fields the class declares are accepted -- anything else answers 400 and names the offending key -- and credential fields are refused outright. Also accepted as a trailing path segment (/{class}/list/field&#x3D;value), which wins when both are sent. | [optional] 

### Return type

[**CountFiledeletequeue200Response**](CountFiledeletequeue200Response.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="New-FogRolepermission"></a>
# **New-FogRolepermission**
> Rolepermission New-FogRolepermission<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Rolepermission] <PSCustomObject><br>

Create a rolepermission

Also reachable as /create and /new.

### Example
```powershell
# general setting of the PowerShell module, e.g. base URL, authentication, etc
$Configuration = Get-Configuration
# Configure HTTP basic authorization: basicAuth
$Configuration.Username = "YOUR_USERNAME"
$Configuration.Password = "YOUR_PASSWORD"

# Configure API key authorization: fogApiToken
$Configuration.ApiKey.fog-api-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-api-token = "Bearer"


# Configure API key authorization: fogUserToken
$Configuration.ApiKey.fog-user-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-user-token = "Bearer"

$Rolepermission = Initialize-Rolepermission -Id 0 -RoleID 0 -Name "MyName" # Rolepermission | 

# Create a rolepermission
try {
    $Result = New-FogRolepermission -Rolepermission $Rolepermission
} catch {
    Write-Host ("Exception occurred when calling New-FogRolepermission: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Rolepermission** | [**Rolepermission**](Rolepermission.md)|  | 

### Return type

[**Rolepermission**](Rolepermission.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Invoke-FogDeleteRolepermission"></a>
# **Invoke-FogDeleteRolepermission**
> DeleteFiledeletequeue200Response Invoke-FogDeleteRolepermission<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>

Delete a rolepermission

Also reachable as /delete and /remove.

### Example
```powershell
# general setting of the PowerShell module, e.g. base URL, authentication, etc
$Configuration = Get-Configuration
# Configure HTTP basic authorization: basicAuth
$Configuration.Username = "YOUR_USERNAME"
$Configuration.Password = "YOUR_PASSWORD"

# Configure API key authorization: fogApiToken
$Configuration.ApiKey.fog-api-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-api-token = "Bearer"


# Configure API key authorization: fogUserToken
$Configuration.ApiKey.fog-user-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-user-token = "Bearer"

$Id = 56 # Int32 | 

# Delete a rolepermission
try {
    $Result = Invoke-FogDeleteRolepermission -Id $Id
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogDeleteRolepermission: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Id** | **Int32**|  | 

### Return type

[**DeleteFiledeletequeue200Response**](DeleteFiledeletequeue200Response.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Invoke-FogIdsRolepermission"></a>
# **Invoke-FogIdsRolepermission**
> SystemCollectionsHashtable[] Invoke-FogIdsRolepermission<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Ids for rolepermission

Unpaged and uncapped. Accepts an optional filter and an optional trailing field name to return instead of the id.

### Example
```powershell
# general setting of the PowerShell module, e.g. base URL, authentication, etc
$Configuration = Get-Configuration
# Configure HTTP basic authorization: basicAuth
$Configuration.Username = "YOUR_USERNAME"
$Configuration.Password = "YOUR_PASSWORD"

# Configure API key authorization: fogApiToken
$Configuration.ApiKey.fog-api-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-api-token = "Bearer"


# Configure API key authorization: fogUserToken
$Configuration.ApiKey.fog-user-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-user-token = "Bearer"

$Filter = "MyFilter" # String | Server-side column filter, written as a URL encoded query string: field=value, joined with & for more than one, ANDed together. A comma separated value matches any of its parts. Only fields the class declares are accepted -- anything else answers 400 and names the offending key -- and credential fields are refused outright. Also accepted as a trailing path segment (/{class}/list/field=value), which wins when both are sent. (optional)

# Ids for rolepermission
try {
    $Result = Invoke-FogIdsRolepermission -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogIdsRolepermission: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Filter** | **String**| Server-side column filter, written as a URL encoded query string: field&#x3D;value, joined with &amp; for more than one, ANDed together. A comma separated value matches any of its parts. Only fields the class declares are accepted -- anything else answers 400 and names the offending key -- and credential fields are refused outright. Also accepted as a trailing path segment (/{class}/list/field&#x3D;value), which wins when both are sent. | [optional] 

### Return type

[**SystemCollectionsHashtable[]**](SystemCollectionsHashtable.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="ConvertTo-FogdivRolepermission"></a>
# **ConvertTo-FogdivRolepermission**
> Rolepermission ConvertTo-FogdivRolepermission<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>

Get one rolepermission by id

Fields withheld from list responses are returned here.

### Example
```powershell
# general setting of the PowerShell module, e.g. base URL, authentication, etc
$Configuration = Get-Configuration
# Configure HTTP basic authorization: basicAuth
$Configuration.Username = "YOUR_USERNAME"
$Configuration.Password = "YOUR_PASSWORD"

# Configure API key authorization: fogApiToken
$Configuration.ApiKey.fog-api-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-api-token = "Bearer"


# Configure API key authorization: fogUserToken
$Configuration.ApiKey.fog-user-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-user-token = "Bearer"

$Id = 56 # Int32 | 

# Get one rolepermission by id
try {
    $Result = ConvertTo-FogdivRolepermission -Id $Id
} catch {
    Write-Host ("Exception occurred when calling ConvertTo-FogdivRolepermission: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Id** | **Int32**|  | 

### Return type

[**Rolepermission**](Rolepermission.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Join-FogRolepermission"></a>
# **Join-FogRolepermission**
> void Join-FogRolepermission<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-JoinRolepermissionRequest] <PSCustomObject><br>

Bulk edit rolepermission

Applies one set of field values to every object named in ids. Fields left out of the body keep their current value on each object, so this edits rather than replaces. It never creates anything, and it matches on nothing but the ids given: a body with no ids matches nothing and succeeds without changing anything.

### Example
```powershell
# general setting of the PowerShell module, e.g. base URL, authentication, etc
$Configuration = Get-Configuration
# Configure HTTP basic authorization: basicAuth
$Configuration.Username = "YOUR_USERNAME"
$Configuration.Password = "YOUR_PASSWORD"

# Configure API key authorization: fogApiToken
$Configuration.ApiKey.fog-api-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-api-token = "Bearer"


# Configure API key authorization: fogUserToken
$Configuration.ApiKey.fog-user-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-user-token = "Bearer"

$JoinRolepermissionRequest = Initialize-JoinRolepermissionRequest -Id 0 -RoleID 0 -Name "MyName" -Ids 0 # JoinRolepermissionRequest | 

# Bulk edit rolepermission
try {
    $Result = Join-FogRolepermission -JoinRolepermissionRequest $JoinRolepermissionRequest
} catch {
    Write-Host ("Exception occurred when calling Join-FogRolepermission: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **JoinRolepermissionRequest** | [**JoinRolepermissionRequest**](JoinRolepermissionRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Invoke-FogListRolepermission"></a>
# **Invoke-FogListRolepermission**
> ListRolepermission200Response Invoke-FogListRolepermission<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Start] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Length] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Expand] <String><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

List rolepermission

Also reachable as /list and /all. Filter with ?filter= or the equivalent trailing path segment; both take field=value pairs joined with &.

### Example
```powershell
# general setting of the PowerShell module, e.g. base URL, authentication, etc
$Configuration = Get-Configuration
# Configure HTTP basic authorization: basicAuth
$Configuration.Username = "YOUR_USERNAME"
$Configuration.Password = "YOUR_PASSWORD"

# Configure API key authorization: fogApiToken
$Configuration.ApiKey.fog-api-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-api-token = "Bearer"


# Configure API key authorization: fogUserToken
$Configuration.ApiKey.fog-user-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-user-token = "Bearer"

$Start = 56 # Int32 | Row offset. Only honoured when length is also sent -- the server reads start from inside the length branch. (optional)
$Length = 56 # Int32 | Page size. Send it, together with start, on every list call: a request with no start is capped at MAX_ROWS and returns a partial result with truncated set. (optional)
$Expand = "MyExpand" # String | Comma separated relations to inline. Forces the page size to EXPAND_MAX_ITEMS, so an expanded page can come back smaller than the length asked for. (optional)
$Filter = "MyFilter" # String | Server-side column filter, written as a URL encoded query string: field=value, joined with & for more than one, ANDed together. A comma separated value matches any of its parts. Only fields the class declares are accepted -- anything else answers 400 and names the offending key -- and credential fields are refused outright. Also accepted as a trailing path segment (/{class}/list/field=value), which wins when both are sent. (optional)

# List rolepermission
try {
    $Result = Invoke-FogListRolepermission -Start $Start -Length $Length -Expand $Expand -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogListRolepermission: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Start** | **Int32**| Row offset. Only honoured when length is also sent -- the server reads start from inside the length branch. | [optional] 
 **Length** | **Int32**| Page size. Send it, together with start, on every list call: a request with no start is capped at MAX_ROWS and returns a partial result with truncated set. | [optional] 
 **Expand** | **String**| Comma separated relations to inline. Forces the page size to EXPAND_MAX_ITEMS, so an expanded page can come back smaller than the length asked for. | [optional] 
 **Filter** | **String**| Server-side column filter, written as a URL encoded query string: field&#x3D;value, joined with &amp; for more than one, ANDed together. A comma separated value matches any of its parts. Only fields the class declares are accepted -- anything else answers 400 and names the offending key -- and credential fields are refused outright. Also accepted as a trailing path segment (/{class}/list/field&#x3D;value), which wins when both are sent. | [optional] 

### Return type

[**ListRolepermission200Response**](ListRolepermission200Response.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Move-FogsRolepermission"></a>
# **Move-FogsRolepermission**
> SystemCollectionsHashtable[] Move-FogsRolepermission<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Id and name pairs for rolepermission

Unpaged and uncapped -- the cheap way to enumerate a large table. Accepts an optional filter.

### Example
```powershell
# general setting of the PowerShell module, e.g. base URL, authentication, etc
$Configuration = Get-Configuration
# Configure HTTP basic authorization: basicAuth
$Configuration.Username = "YOUR_USERNAME"
$Configuration.Password = "YOUR_PASSWORD"

# Configure API key authorization: fogApiToken
$Configuration.ApiKey.fog-api-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-api-token = "Bearer"


# Configure API key authorization: fogUserToken
$Configuration.ApiKey.fog-user-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-user-token = "Bearer"

$Filter = "MyFilter" # String | Server-side column filter, written as a URL encoded query string: field=value, joined with & for more than one, ANDed together. A comma separated value matches any of its parts. Only fields the class declares are accepted -- anything else answers 400 and names the offending key -- and credential fields are refused outright. Also accepted as a trailing path segment (/{class}/list/field=value), which wins when both are sent. (optional)

# Id and name pairs for rolepermission
try {
    $Result = Move-FogsRolepermission -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Move-FogsRolepermission: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Filter** | **String**| Server-side column filter, written as a URL encoded query string: field&#x3D;value, joined with &amp; for more than one, ANDed together. A comma separated value matches any of its parts. Only fields the class declares are accepted -- anything else answers 400 and names the offending key -- and credential fields are refused outright. Also accepted as a trailing path segment (/{class}/list/field&#x3D;value), which wins when both are sent. | [optional] 

### Return type

[**SystemCollectionsHashtable[]**](SystemCollectionsHashtable.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Search-FogRolepermission"></a>
# **Search-FogRolepermission**
> ListRolepermission200Response Search-FogRolepermission<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Item] <String><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Start] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Length] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Expand] <String><br>

Search rolepermission

Matches the term against the class name field. Returns the same envelope as a list. Takes no filter -- the match is the whole query.

### Example
```powershell
# general setting of the PowerShell module, e.g. base URL, authentication, etc
$Configuration = Get-Configuration
# Configure HTTP basic authorization: basicAuth
$Configuration.Username = "YOUR_USERNAME"
$Configuration.Password = "YOUR_PASSWORD"

# Configure API key authorization: fogApiToken
$Configuration.ApiKey.fog-api-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-api-token = "Bearer"


# Configure API key authorization: fogUserToken
$Configuration.ApiKey.fog-user-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-user-token = "Bearer"

$Item = "MyItem" # String | Text to match against the id and name. A few classes match more: host also on MAC, storagenode on node hostname, setting on value.
$Start = 56 # Int32 | Row offset. Only honoured when length is also sent -- the server reads start from inside the length branch. (optional)
$Length = 56 # Int32 | Page size. Send it, together with start, on every list call: a request with no start is capped at MAX_ROWS and returns a partial result with truncated set. (optional)
$Expand = "MyExpand" # String | Comma separated relations to inline. Forces the page size to EXPAND_MAX_ITEMS, so an expanded page can come back smaller than the length asked for. (optional)

# Search rolepermission
try {
    $Result = Search-FogRolepermission -Item $Item -Start $Start -Length $Length -Expand $Expand
} catch {
    Write-Host ("Exception occurred when calling Search-FogRolepermission: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Item** | **String**| Text to match against the id and name. A few classes match more: host also on MAC, storagenode on node hostname, setting on value. | 
 **Start** | **Int32**| Row offset. Only honoured when length is also sent -- the server reads start from inside the length branch. | [optional] 
 **Length** | **Int32**| Page size. Send it, together with start, on every list call: a request with no start is capped at MAX_ROWS and returns a partial result with truncated set. | [optional] 
 **Expand** | **String**| Comma separated relations to inline. Forces the page size to EXPAND_MAX_ITEMS, so an expanded page can come back smaller than the length asked for. | [optional] 

### Return type

[**ListRolepermission200Response**](ListRolepermission200Response.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Update-FogRolepermission"></a>
# **Update-FogRolepermission**
> Rolepermission Update-FogRolepermission<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Rolepermission] <PSCustomObject><br>

Update a rolepermission

Also reachable as /update and /edit. Send only the fields being changed.

### Example
```powershell
# general setting of the PowerShell module, e.g. base URL, authentication, etc
$Configuration = Get-Configuration
# Configure HTTP basic authorization: basicAuth
$Configuration.Username = "YOUR_USERNAME"
$Configuration.Password = "YOUR_PASSWORD"

# Configure API key authorization: fogApiToken
$Configuration.ApiKey.fog-api-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-api-token = "Bearer"


# Configure API key authorization: fogUserToken
$Configuration.ApiKey.fog-user-token = "YOUR_API_KEY"
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
#$Configuration.ApiKeyPrefix.fog-user-token = "Bearer"

$Id = 56 # Int32 | 
$Rolepermission = Initialize-Rolepermission -Id 0 -RoleID 0 -Name "MyName" # Rolepermission | 

# Update a rolepermission
try {
    $Result = Update-FogRolepermission -Id $Id -Rolepermission $Rolepermission
} catch {
    Write-Host ("Exception occurred when calling Update-FogRolepermission: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Id** | **Int32**|  | 
 **Rolepermission** | [**Rolepermission**](Rolepermission.md)|  | 

### Return type

[**Rolepermission**](Rolepermission.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

