# FogApi.FogApi\Api.FogHostApi

All URIs are relative to *http://fog-dev/fog*

Method | HTTP request | Description
------------- | ------------- | -------------
[**Stop-FogHost**](FogHostApi.md#Stop-FogHost) | **DELETE** /host/{id}/cancel | Cancel a host task
[**Invoke-FogCountHost**](FogHostApi.md#Invoke-FogCountHost) | **GET** /host/count | Count host
[**New-FogHost**](FogHostApi.md#New-FogHost) | **POST** /host | Create a host
[**Invoke-FogDeleteHost**](FogHostApi.md#Invoke-FogDeleteHost) | **DELETE** /host/{id} | Delete a host
[**Invoke-FogIdsHost**](FogHostApi.md#Invoke-FogIdsHost) | **GET** /host/ids | Ids for host
[**ConvertTo-FogdivHost**](FogHostApi.md#ConvertTo-FogdivHost) | **GET** /host/{id} | Get one host by id
[**Join-FogHost**](FogHostApi.md#Join-FogHost) | **PUT** /host/join | Bulk edit host
[**Invoke-FogListHost**](FogHostApi.md#Invoke-FogListHost) | **GET** /host | List host
[**Move-FogsHost**](FogHostApi.md#Move-FogsHost) | **GET** /host/names | Id and name pairs for host
[**Search-FogHost**](FogHostApi.md#Search-FogHost) | **GET** /host/search/{item} | Search host
[**Invoke-FogTaskHost**](FogHostApi.md#Invoke-FogTaskHost) | **POST** /host/{id}/task | Queue a task against a host
[**Update-FogHost**](FogHostApi.md#Update-FogHost) | **PUT** /host/{id} | Update a host


<a id="Stop-FogHost"></a>
# **Stop-FogHost**
> DeleteFiledeletequeue200Response Stop-FogHost<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>

Cancel a host task

Only a task in a queued or in-progress state can be cancelled. Naming a resource whose task has already finished -- Complete, Cancelled or Failed -- answers 409 rather than reporting a success it did not perform.

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

# Cancel a host task
try {
    $Result = Stop-FogHost -Id $Id
} catch {
    Write-Host ("Exception occurred when calling Stop-FogHost: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="Invoke-FogCountHost"></a>
# **Invoke-FogCountHost**
> CountFiledeletequeue200Response Invoke-FogCountHost<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Count host

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

# Count host
try {
    $Result = Invoke-FogCountHost -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogCountHost: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="New-FogHost"></a>
# **New-FogHost**
> ModelHost New-FogHost<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-ModelHost] <PSCustomObject><br>

Create a host

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

$ModelHost = Initialize-ModelHost -Id 0 -Name "MyName" -Description "MyDescription" -Ip "MyIp" -ImageID 0 -Building 0 -Deployed (Get-Date) -UseAD "MyUseAD" -ADDomain "MyADDomain" -ADOU "MyADOU" -ADUser "MyADUser" -ADPass "MyADPass" -ADPassLegacy "MyADPassLegacy" -ProductKey "MyProductKey" -PrinterLevel "MyPrinterLevel" -KernelArgs "MyKernelArgs" -Kernel "MyKernel" -KernelDevice "MyKernelDevice" -Init "MyInit" -Pending "0" -PubKey "MyPubKey" -SecTok "MySecTok" -PrevSecTok "MyPrevSecTok" -SecTime (Get-Date) -Pingstatus "MyPingstatus" -Pingmethod "MyPingmethod" -Lastping (Get-Date) -Lastcheckin (Get-Date) -Biosexit "MyBiosexit" -Efiexit "MyEfiexit" -Enforce "0" -Token "MyToken" -Tokenlock 0 -Mac  -Primac  -Imagename  -Groups  -Hostscreen  -Hostalo  -OptimalStorageNode  -Printers  -Snapins  -Modules  -Inventory  -Task  -Snapinjob  -Users  -Fingerprint  -Powermanagementtasks # ModelHost | 

# Create a host
try {
    $Result = New-FogHost -ModelHost $ModelHost
} catch {
    Write-Host ("Exception occurred when calling New-FogHost: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **ModelHost** | [**ModelHost**](ModelHost.md)|  | 

### Return type

[**ModelHost**](ModelHost.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Invoke-FogDeleteHost"></a>
# **Invoke-FogDeleteHost**
> DeleteFiledeletequeue200Response Invoke-FogDeleteHost<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>

Delete a host

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

# Delete a host
try {
    $Result = Invoke-FogDeleteHost -Id $Id
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogDeleteHost: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="Invoke-FogIdsHost"></a>
# **Invoke-FogIdsHost**
> SystemCollectionsHashtable[] Invoke-FogIdsHost<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Ids for host

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

# Ids for host
try {
    $Result = Invoke-FogIdsHost -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogIdsHost: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="ConvertTo-FogdivHost"></a>
# **ConvertTo-FogdivHost**
> ModelHost ConvertTo-FogdivHost<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>

Get one host by id

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

# Get one host by id
try {
    $Result = ConvertTo-FogdivHost -Id $Id
} catch {
    Write-Host ("Exception occurred when calling ConvertTo-FogdivHost: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Id** | **Int32**|  | 

### Return type

[**ModelHost**](ModelHost.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Join-FogHost"></a>
# **Join-FogHost**
> void Join-FogHost<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-JoinHostRequest] <PSCustomObject><br>

Bulk edit host

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

$JoinHostRequest = Initialize-JoinHostRequest -Id 0 -Name "MyName" -Description "MyDescription" -Ip "MyIp" -ImageID 0 -Building 0 -Deployed (Get-Date) -UseAD "MyUseAD" -ADDomain "MyADDomain" -ADOU "MyADOU" -ADUser "MyADUser" -ADPass "MyADPass" -ADPassLegacy "MyADPassLegacy" -ProductKey "MyProductKey" -PrinterLevel "MyPrinterLevel" -KernelArgs "MyKernelArgs" -Kernel "MyKernel" -KernelDevice "MyKernelDevice" -Init "MyInit" -Pending "0" -PubKey "MyPubKey" -SecTok "MySecTok" -PrevSecTok "MyPrevSecTok" -SecTime (Get-Date) -Pingstatus "MyPingstatus" -Pingmethod "MyPingmethod" -Lastping (Get-Date) -Lastcheckin (Get-Date) -Biosexit "MyBiosexit" -Efiexit "MyEfiexit" -Enforce "0" -Token "MyToken" -Tokenlock 0 -Mac  -Primac  -Imagename  -Groups  -Hostscreen  -Hostalo  -OptimalStorageNode  -Printers  -Snapins  -Modules  -Inventory  -Task  -Snapinjob  -Users  -Fingerprint  -Powermanagementtasks  -Ids 0 # JoinHostRequest | 

# Bulk edit host
try {
    $Result = Join-FogHost -JoinHostRequest $JoinHostRequest
} catch {
    Write-Host ("Exception occurred when calling Join-FogHost: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **JoinHostRequest** | [**JoinHostRequest**](JoinHostRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Invoke-FogListHost"></a>
# **Invoke-FogListHost**
> ListHost200Response Invoke-FogListHost<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Start] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Length] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Expand] <String><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

List host

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

# List host
try {
    $Result = Invoke-FogListHost -Start $Start -Length $Length -Expand $Expand -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogListHost: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

[**ListHost200Response**](ListHost200Response.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Move-FogsHost"></a>
# **Move-FogsHost**
> SystemCollectionsHashtable[] Move-FogsHost<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Id and name pairs for host

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

# Id and name pairs for host
try {
    $Result = Move-FogsHost -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Move-FogsHost: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="Search-FogHost"></a>
# **Search-FogHost**
> ListHost200Response Search-FogHost<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Item] <String><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Start] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Length] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Expand] <String><br>

Search host

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

# Search host
try {
    $Result = Search-FogHost -Item $Item -Start $Start -Length $Length -Expand $Expand
} catch {
    Write-Host ("Exception occurred when calling Search-FogHost: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

[**ListHost200Response**](ListHost200Response.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Invoke-FogTaskHost"></a>
# **Invoke-FogTaskHost**
> ListEnvelope Invoke-FogTaskHost<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-TaskFiledeletequeueRequest] <PSCustomObject><br>

Queue a task against a host

Body accepts taskTypeID, taskName, shutdown, debug, deploySnapins, passreset, sessionjoin and wol. Wake-on-lan is this route with wol set, not a route of its own.

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
$TaskFiledeletequeueRequestTaskTypeID = Initialize-TaskFiledeletequeueRequestTaskTypeID 
$TaskFiledeletequeueRequestShutdown = Initialize-TaskFiledeletequeueRequestShutdown 
$TaskFiledeletequeueRequestDeploySnapins = Initialize-TaskFiledeletequeueRequestDeploySnapins 
$TaskFiledeletequeueRequest = Initialize-TaskFiledeletequeueRequest -TaskTypeID $TaskFiledeletequeueRequestTaskTypeID -TaskName "MyTaskName" -Shutdown $TaskFiledeletequeueRequestShutdown -Debug $TaskFiledeletequeueRequestShutdown -DeploySnapins $TaskFiledeletequeueRequestDeploySnapins -Passreset "MyPassreset" -Sessionjoin $TaskFiledeletequeueRequestShutdown -Wol $TaskFiledeletequeueRequestShutdown # TaskFiledeletequeueRequest | 

# Queue a task against a host
try {
    $Result = Invoke-FogTaskHost -Id $Id -TaskFiledeletequeueRequest $TaskFiledeletequeueRequest
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogTaskHost: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Id** | **Int32**|  | 
 **TaskFiledeletequeueRequest** | [**TaskFiledeletequeueRequest**](TaskFiledeletequeueRequest.md)|  | 

### Return type

[**ListEnvelope**](ListEnvelope.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Update-FogHost"></a>
# **Update-FogHost**
> ModelHost Update-FogHost<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-ModelHost] <PSCustomObject><br>

Update a host

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
$ModelHost = Initialize-ModelHost -Id 0 -Name "MyName" -Description "MyDescription" -Ip "MyIp" -ImageID 0 -Building 0 -Deployed (Get-Date) -UseAD "MyUseAD" -ADDomain "MyADDomain" -ADOU "MyADOU" -ADUser "MyADUser" -ADPass "MyADPass" -ADPassLegacy "MyADPassLegacy" -ProductKey "MyProductKey" -PrinterLevel "MyPrinterLevel" -KernelArgs "MyKernelArgs" -Kernel "MyKernel" -KernelDevice "MyKernelDevice" -Init "MyInit" -Pending "0" -PubKey "MyPubKey" -SecTok "MySecTok" -PrevSecTok "MyPrevSecTok" -SecTime (Get-Date) -Pingstatus "MyPingstatus" -Pingmethod "MyPingmethod" -Lastping (Get-Date) -Lastcheckin (Get-Date) -Biosexit "MyBiosexit" -Efiexit "MyEfiexit" -Enforce "0" -Token "MyToken" -Tokenlock 0 -Mac  -Primac  -Imagename  -Groups  -Hostscreen  -Hostalo  -OptimalStorageNode  -Printers  -Snapins  -Modules  -Inventory  -Task  -Snapinjob  -Users  -Fingerprint  -Powermanagementtasks # ModelHost | 

# Update a host
try {
    $Result = Update-FogHost -Id $Id -ModelHost $ModelHost
} catch {
    Write-Host ("Exception occurred when calling Update-FogHost: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Id** | **Int32**|  | 
 **ModelHost** | [**ModelHost**](ModelHost.md)|  | 

### Return type

[**ModelHost**](ModelHost.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

