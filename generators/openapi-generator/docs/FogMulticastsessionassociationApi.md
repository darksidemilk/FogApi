# FogApi.FogApi\Api.FogMulticastsessionassociationApi

All URIs are relative to *https://fog.example.invalid/fog*

Method | HTTP request | Description
------------- | ------------- | -------------
[**Invoke-FogCountMulticastsessionassociation**](FogMulticastsessionassociationApi.md#Invoke-FogCountMulticastsessionassociation) | **GET** /multicastsessionassociation/count | Count multicastsessionassociation
[**New-FogMulticastsessionassociation**](FogMulticastsessionassociationApi.md#New-FogMulticastsessionassociation) | **POST** /multicastsessionassociation | Create a multicastsessionassociation
[**Invoke-FogDeleteMulticastsessionassociation**](FogMulticastsessionassociationApi.md#Invoke-FogDeleteMulticastsessionassociation) | **DELETE** /multicastsessionassociation/{id} | Delete a multicastsessionassociation
[**Invoke-FogIdsMulticastsessionassociation**](FogMulticastsessionassociationApi.md#Invoke-FogIdsMulticastsessionassociation) | **GET** /multicastsessionassociation/ids | Ids for multicastsessionassociation
[**ConvertTo-FogdivMulticastsessionassociation**](FogMulticastsessionassociationApi.md#ConvertTo-FogdivMulticastsessionassociation) | **GET** /multicastsessionassociation/{id} | Get one multicastsessionassociation by id
[**Join-FogMulticastsessionassociation**](FogMulticastsessionassociationApi.md#Join-FogMulticastsessionassociation) | **PUT** /multicastsessionassociation/join | Bulk edit multicastsessionassociation
[**Invoke-FogListMulticastsessionassociation**](FogMulticastsessionassociationApi.md#Invoke-FogListMulticastsessionassociation) | **GET** /multicastsessionassociation | List multicastsessionassociation
[**Move-FogsMulticastsessionassociation**](FogMulticastsessionassociationApi.md#Move-FogsMulticastsessionassociation) | **GET** /multicastsessionassociation/names | Id and name pairs for multicastsessionassociation
[**Update-FogMulticastsessionassociation**](FogMulticastsessionassociationApi.md#Update-FogMulticastsessionassociation) | **PUT** /multicastsessionassociation/{id} | Update a multicastsessionassociation


<a id="Invoke-FogCountMulticastsessionassociation"></a>
# **Invoke-FogCountMulticastsessionassociation**
> CountFiledeletequeue200Response Invoke-FogCountMulticastsessionassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Count multicastsessionassociation

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

# Count multicastsessionassociation
try {
    $Result = Invoke-FogCountMulticastsessionassociation -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogCountMulticastsessionassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="New-FogMulticastsessionassociation"></a>
# **New-FogMulticastsessionassociation**
> Multicastsessionassociation New-FogMulticastsessionassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Multicastsessionassociation] <PSCustomObject><br>

Create a multicastsessionassociation

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

$Multicastsessionassociation = Initialize-Multicastsessionassociation -Id 0 -MsID 0 -TaskID 0 # Multicastsessionassociation | 

# Create a multicastsessionassociation
try {
    $Result = New-FogMulticastsessionassociation -Multicastsessionassociation $Multicastsessionassociation
} catch {
    Write-Host ("Exception occurred when calling New-FogMulticastsessionassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Multicastsessionassociation** | [**Multicastsessionassociation**](Multicastsessionassociation.md)|  | 

### Return type

[**Multicastsessionassociation**](Multicastsessionassociation.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Invoke-FogDeleteMulticastsessionassociation"></a>
# **Invoke-FogDeleteMulticastsessionassociation**
> DeleteFiledeletequeue200Response Invoke-FogDeleteMulticastsessionassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>

Delete a multicastsessionassociation

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

# Delete a multicastsessionassociation
try {
    $Result = Invoke-FogDeleteMulticastsessionassociation -Id $Id
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogDeleteMulticastsessionassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="Invoke-FogIdsMulticastsessionassociation"></a>
# **Invoke-FogIdsMulticastsessionassociation**
> SystemCollectionsHashtable[] Invoke-FogIdsMulticastsessionassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Ids for multicastsessionassociation

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

# Ids for multicastsessionassociation
try {
    $Result = Invoke-FogIdsMulticastsessionassociation -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogIdsMulticastsessionassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="ConvertTo-FogdivMulticastsessionassociation"></a>
# **ConvertTo-FogdivMulticastsessionassociation**
> Multicastsessionassociation ConvertTo-FogdivMulticastsessionassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>

Get one multicastsessionassociation by id

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

# Get one multicastsessionassociation by id
try {
    $Result = ConvertTo-FogdivMulticastsessionassociation -Id $Id
} catch {
    Write-Host ("Exception occurred when calling ConvertTo-FogdivMulticastsessionassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Id** | **Int32**|  | 

### Return type

[**Multicastsessionassociation**](Multicastsessionassociation.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Join-FogMulticastsessionassociation"></a>
# **Join-FogMulticastsessionassociation**
> void Join-FogMulticastsessionassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-JoinMulticastsessionassociationRequest] <PSCustomObject><br>

Bulk edit multicastsessionassociation

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

$JoinMulticastsessionassociationRequest = Initialize-JoinMulticastsessionassociationRequest -Id 0 -MsID 0 -TaskID 0 -Ids 0 # JoinMulticastsessionassociationRequest | 

# Bulk edit multicastsessionassociation
try {
    $Result = Join-FogMulticastsessionassociation -JoinMulticastsessionassociationRequest $JoinMulticastsessionassociationRequest
} catch {
    Write-Host ("Exception occurred when calling Join-FogMulticastsessionassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **JoinMulticastsessionassociationRequest** | [**JoinMulticastsessionassociationRequest**](JoinMulticastsessionassociationRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Invoke-FogListMulticastsessionassociation"></a>
# **Invoke-FogListMulticastsessionassociation**
> ListMulticastsessionassociation200Response Invoke-FogListMulticastsessionassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Start] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Length] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Expand] <String><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

List multicastsessionassociation

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

# List multicastsessionassociation
try {
    $Result = Invoke-FogListMulticastsessionassociation -Start $Start -Length $Length -Expand $Expand -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogListMulticastsessionassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

[**ListMulticastsessionassociation200Response**](ListMulticastsessionassociation200Response.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Move-FogsMulticastsessionassociation"></a>
# **Move-FogsMulticastsessionassociation**
> SystemCollectionsHashtable[] Move-FogsMulticastsessionassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Id and name pairs for multicastsessionassociation

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

# Id and name pairs for multicastsessionassociation
try {
    $Result = Move-FogsMulticastsessionassociation -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Move-FogsMulticastsessionassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="Update-FogMulticastsessionassociation"></a>
# **Update-FogMulticastsessionassociation**
> Multicastsessionassociation Update-FogMulticastsessionassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Multicastsessionassociation] <PSCustomObject><br>

Update a multicastsessionassociation

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
$Multicastsessionassociation = Initialize-Multicastsessionassociation -Id 0 -MsID 0 -TaskID 0 # Multicastsessionassociation | 

# Update a multicastsessionassociation
try {
    $Result = Update-FogMulticastsessionassociation -Id $Id -Multicastsessionassociation $Multicastsessionassociation
} catch {
    Write-Host ("Exception occurred when calling Update-FogMulticastsessionassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Id** | **Int32**|  | 
 **Multicastsessionassociation** | [**Multicastsessionassociation**](Multicastsessionassociation.md)|  | 

### Return type

[**Multicastsessionassociation**](Multicastsessionassociation.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

