# FogApi.FogApi\Api.FogIpxeApi

All URIs are relative to *https://fog.example.invalid/fog*

Method | HTTP request | Description
------------- | ------------- | -------------
[**Invoke-FogCountIpxe**](FogIpxeApi.md#Invoke-FogCountIpxe) | **GET** /ipxe/count | Count ipxe
[**New-FogIpxe**](FogIpxeApi.md#New-FogIpxe) | **POST** /ipxe | Create a ipxe
[**Invoke-FogDeleteIpxe**](FogIpxeApi.md#Invoke-FogDeleteIpxe) | **DELETE** /ipxe/{id} | Delete a ipxe
[**Invoke-FogIdsIpxe**](FogIpxeApi.md#Invoke-FogIdsIpxe) | **GET** /ipxe/ids | Ids for ipxe
[**ConvertTo-FogdivIpxe**](FogIpxeApi.md#ConvertTo-FogdivIpxe) | **GET** /ipxe/{id} | Get one ipxe by id
[**Join-FogIpxe**](FogIpxeApi.md#Join-FogIpxe) | **PUT** /ipxe/join | Bulk edit ipxe
[**Invoke-FogListIpxe**](FogIpxeApi.md#Invoke-FogListIpxe) | **GET** /ipxe | List ipxe
[**Move-FogsIpxe**](FogIpxeApi.md#Move-FogsIpxe) | **GET** /ipxe/names | Id and name pairs for ipxe
[**Update-FogIpxe**](FogIpxeApi.md#Update-FogIpxe) | **PUT** /ipxe/{id} | Update a ipxe


<a id="Invoke-FogCountIpxe"></a>
# **Invoke-FogCountIpxe**
> CountFiledeletequeue200Response Invoke-FogCountIpxe<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Count ipxe

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

# Count ipxe
try {
    $Result = Invoke-FogCountIpxe -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogCountIpxe: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="New-FogIpxe"></a>
# **New-FogIpxe**
> Ipxe New-FogIpxe<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Ipxe] <PSCustomObject><br>

Create a ipxe

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

$Ipxe = Initialize-Ipxe -Id 0 -Product "MyProduct" -Manufacturer "MyManufacturer" -Mac "MyMac" -Success "MySuccess" -Failure "MyFailure" -File "MyFile" -Version "MyVersion" # Ipxe | 

# Create a ipxe
try {
    $Result = New-FogIpxe -Ipxe $Ipxe
} catch {
    Write-Host ("Exception occurred when calling New-FogIpxe: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Ipxe** | [**Ipxe**](Ipxe.md)|  | 

### Return type

[**Ipxe**](Ipxe.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Invoke-FogDeleteIpxe"></a>
# **Invoke-FogDeleteIpxe**
> DeleteFiledeletequeue200Response Invoke-FogDeleteIpxe<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>

Delete a ipxe

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

# Delete a ipxe
try {
    $Result = Invoke-FogDeleteIpxe -Id $Id
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogDeleteIpxe: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="Invoke-FogIdsIpxe"></a>
# **Invoke-FogIdsIpxe**
> SystemCollectionsHashtable[] Invoke-FogIdsIpxe<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Ids for ipxe

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

# Ids for ipxe
try {
    $Result = Invoke-FogIdsIpxe -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogIdsIpxe: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="ConvertTo-FogdivIpxe"></a>
# **ConvertTo-FogdivIpxe**
> Ipxe ConvertTo-FogdivIpxe<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>

Get one ipxe by id

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

# Get one ipxe by id
try {
    $Result = ConvertTo-FogdivIpxe -Id $Id
} catch {
    Write-Host ("Exception occurred when calling ConvertTo-FogdivIpxe: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Id** | **Int32**|  | 

### Return type

[**Ipxe**](Ipxe.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Join-FogIpxe"></a>
# **Join-FogIpxe**
> void Join-FogIpxe<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-JoinIpxeRequest] <PSCustomObject><br>

Bulk edit ipxe

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

$JoinIpxeRequest = Initialize-JoinIpxeRequest -Id 0 -Product "MyProduct" -Manufacturer "MyManufacturer" -Mac "MyMac" -Success "MySuccess" -Failure "MyFailure" -File "MyFile" -Version "MyVersion" -Ids 0 # JoinIpxeRequest | 

# Bulk edit ipxe
try {
    $Result = Join-FogIpxe -JoinIpxeRequest $JoinIpxeRequest
} catch {
    Write-Host ("Exception occurred when calling Join-FogIpxe: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **JoinIpxeRequest** | [**JoinIpxeRequest**](JoinIpxeRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Invoke-FogListIpxe"></a>
# **Invoke-FogListIpxe**
> ListIpxe200Response Invoke-FogListIpxe<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Start] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Length] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Expand] <String><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

List ipxe

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

# List ipxe
try {
    $Result = Invoke-FogListIpxe -Start $Start -Length $Length -Expand $Expand -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogListIpxe: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

[**ListIpxe200Response**](ListIpxe200Response.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Move-FogsIpxe"></a>
# **Move-FogsIpxe**
> SystemCollectionsHashtable[] Move-FogsIpxe<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Id and name pairs for ipxe

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

# Id and name pairs for ipxe
try {
    $Result = Move-FogsIpxe -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Move-FogsIpxe: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="Update-FogIpxe"></a>
# **Update-FogIpxe**
> Ipxe Update-FogIpxe<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Ipxe] <PSCustomObject><br>

Update a ipxe

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
$Ipxe = Initialize-Ipxe -Id 0 -Product "MyProduct" -Manufacturer "MyManufacturer" -Mac "MyMac" -Success "MySuccess" -Failure "MyFailure" -File "MyFile" -Version "MyVersion" # Ipxe | 

# Update a ipxe
try {
    $Result = Update-FogIpxe -Id $Id -Ipxe $Ipxe
} catch {
    Write-Host ("Exception occurred when calling Update-FogIpxe: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Id** | **Int32**|  | 
 **Ipxe** | [**Ipxe**](Ipxe.md)|  | 

### Return type

[**Ipxe**](Ipxe.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

