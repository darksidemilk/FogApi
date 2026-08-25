# FogApi.FogApi\Api.FogLdapgroupusergroupassociationApi

All URIs are relative to *http://fog-dev/fog*

Method | HTTP request | Description
------------- | ------------- | -------------
[**Invoke-FogCountLdapgroupusergroupassociation**](FogLdapgroupusergroupassociationApi.md#Invoke-FogCountLdapgroupusergroupassociation) | **GET** /ldapgroupusergroupassociation/count | Count ldapgroupusergroupassociation
[**New-FogLdapgroupusergroupassociation**](FogLdapgroupusergroupassociationApi.md#New-FogLdapgroupusergroupassociation) | **POST** /ldapgroupusergroupassociation | Create a ldapgroupusergroupassociation
[**Invoke-FogDeleteLdapgroupusergroupassociation**](FogLdapgroupusergroupassociationApi.md#Invoke-FogDeleteLdapgroupusergroupassociation) | **DELETE** /ldapgroupusergroupassociation/{id} | Delete a ldapgroupusergroupassociation
[**Invoke-FogIdsLdapgroupusergroupassociation**](FogLdapgroupusergroupassociationApi.md#Invoke-FogIdsLdapgroupusergroupassociation) | **GET** /ldapgroupusergroupassociation/ids | Ids for ldapgroupusergroupassociation
[**ConvertTo-FogdivLdapgroupusergroupassociation**](FogLdapgroupusergroupassociationApi.md#ConvertTo-FogdivLdapgroupusergroupassociation) | **GET** /ldapgroupusergroupassociation/{id} | Get one ldapgroupusergroupassociation by id
[**Join-FogLdapgroupusergroupassociation**](FogLdapgroupusergroupassociationApi.md#Join-FogLdapgroupusergroupassociation) | **PUT** /ldapgroupusergroupassociation/join | Bulk edit ldapgroupusergroupassociation
[**Invoke-FogListLdapgroupusergroupassociation**](FogLdapgroupusergroupassociationApi.md#Invoke-FogListLdapgroupusergroupassociation) | **GET** /ldapgroupusergroupassociation | List ldapgroupusergroupassociation
[**Move-FogsLdapgroupusergroupassociation**](FogLdapgroupusergroupassociationApi.md#Move-FogsLdapgroupusergroupassociation) | **GET** /ldapgroupusergroupassociation/names | Id and name pairs for ldapgroupusergroupassociation
[**Search-FogLdapgroupusergroupassociation**](FogLdapgroupusergroupassociationApi.md#Search-FogLdapgroupusergroupassociation) | **GET** /ldapgroupusergroupassociation/search/{item} | Search ldapgroupusergroupassociation
[**Update-FogLdapgroupusergroupassociation**](FogLdapgroupusergroupassociationApi.md#Update-FogLdapgroupusergroupassociation) | **PUT** /ldapgroupusergroupassociation/{id} | Update a ldapgroupusergroupassociation


<a id="Invoke-FogCountLdapgroupusergroupassociation"></a>
# **Invoke-FogCountLdapgroupusergroupassociation**
> CountFiledeletequeue200Response Invoke-FogCountLdapgroupusergroupassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Count ldapgroupusergroupassociation

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

# Count ldapgroupusergroupassociation
try {
    $Result = Invoke-FogCountLdapgroupusergroupassociation -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogCountLdapgroupusergroupassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="New-FogLdapgroupusergroupassociation"></a>
# **New-FogLdapgroupusergroupassociation**
> Ldapgroupusergroupassociation New-FogLdapgroupusergroupassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Ldapgroupusergroupassociation] <PSCustomObject><br>

Create a ldapgroupusergroupassociation

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

$Ldapgroupusergroupassociation = Initialize-Ldapgroupusergroupassociation -Id "MyId" -Name "MyName" -LdapgroupID "MyLdapgroupID" -UsergroupID "MyUsergroupID" # Ldapgroupusergroupassociation | 

# Create a ldapgroupusergroupassociation
try {
    $Result = New-FogLdapgroupusergroupassociation -Ldapgroupusergroupassociation $Ldapgroupusergroupassociation
} catch {
    Write-Host ("Exception occurred when calling New-FogLdapgroupusergroupassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Ldapgroupusergroupassociation** | [**Ldapgroupusergroupassociation**](Ldapgroupusergroupassociation.md)|  | 

### Return type

[**Ldapgroupusergroupassociation**](Ldapgroupusergroupassociation.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Invoke-FogDeleteLdapgroupusergroupassociation"></a>
# **Invoke-FogDeleteLdapgroupusergroupassociation**
> DeleteFiledeletequeue200Response Invoke-FogDeleteLdapgroupusergroupassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>

Delete a ldapgroupusergroupassociation

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

# Delete a ldapgroupusergroupassociation
try {
    $Result = Invoke-FogDeleteLdapgroupusergroupassociation -Id $Id
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogDeleteLdapgroupusergroupassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="Invoke-FogIdsLdapgroupusergroupassociation"></a>
# **Invoke-FogIdsLdapgroupusergroupassociation**
> SystemCollectionsHashtable[] Invoke-FogIdsLdapgroupusergroupassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Ids for ldapgroupusergroupassociation

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

# Ids for ldapgroupusergroupassociation
try {
    $Result = Invoke-FogIdsLdapgroupusergroupassociation -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogIdsLdapgroupusergroupassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="ConvertTo-FogdivLdapgroupusergroupassociation"></a>
# **ConvertTo-FogdivLdapgroupusergroupassociation**
> Ldapgroupusergroupassociation ConvertTo-FogdivLdapgroupusergroupassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>

Get one ldapgroupusergroupassociation by id

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

# Get one ldapgroupusergroupassociation by id
try {
    $Result = ConvertTo-FogdivLdapgroupusergroupassociation -Id $Id
} catch {
    Write-Host ("Exception occurred when calling ConvertTo-FogdivLdapgroupusergroupassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Id** | **Int32**|  | 

### Return type

[**Ldapgroupusergroupassociation**](Ldapgroupusergroupassociation.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Join-FogLdapgroupusergroupassociation"></a>
# **Join-FogLdapgroupusergroupassociation**
> void Join-FogLdapgroupusergroupassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-JoinLdapgroupusergroupassociationRequest] <PSCustomObject><br>

Bulk edit ldapgroupusergroupassociation

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

$JoinLdapgroupusergroupassociationRequest = Initialize-JoinLdapgroupusergroupassociationRequest -Id "MyId" -Name "MyName" -LdapgroupID "MyLdapgroupID" -UsergroupID "MyUsergroupID" -Ids 0 # JoinLdapgroupusergroupassociationRequest | 

# Bulk edit ldapgroupusergroupassociation
try {
    $Result = Join-FogLdapgroupusergroupassociation -JoinLdapgroupusergroupassociationRequest $JoinLdapgroupusergroupassociationRequest
} catch {
    Write-Host ("Exception occurred when calling Join-FogLdapgroupusergroupassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **JoinLdapgroupusergroupassociationRequest** | [**JoinLdapgroupusergroupassociationRequest**](JoinLdapgroupusergroupassociationRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Invoke-FogListLdapgroupusergroupassociation"></a>
# **Invoke-FogListLdapgroupusergroupassociation**
> ListLdapgroupusergroupassociation200Response Invoke-FogListLdapgroupusergroupassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Start] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Length] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Expand] <String><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

List ldapgroupusergroupassociation

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

# List ldapgroupusergroupassociation
try {
    $Result = Invoke-FogListLdapgroupusergroupassociation -Start $Start -Length $Length -Expand $Expand -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Invoke-FogListLdapgroupusergroupassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

[**ListLdapgroupusergroupassociation200Response**](ListLdapgroupusergroupassociation200Response.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Move-FogsLdapgroupusergroupassociation"></a>
# **Move-FogsLdapgroupusergroupassociation**
> SystemCollectionsHashtable[] Move-FogsLdapgroupusergroupassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Filter] <String><br>

Id and name pairs for ldapgroupusergroupassociation

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

# Id and name pairs for ldapgroupusergroupassociation
try {
    $Result = Move-FogsLdapgroupusergroupassociation -Filter $Filter
} catch {
    Write-Host ("Exception occurred when calling Move-FogsLdapgroupusergroupassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

<a id="Search-FogLdapgroupusergroupassociation"></a>
# **Search-FogLdapgroupusergroupassociation**
> ListLdapgroupusergroupassociation200Response Search-FogLdapgroupusergroupassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Item] <String><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Start] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Length] <System.Nullable[Int32]><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Expand] <String><br>

Search ldapgroupusergroupassociation

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

# Search ldapgroupusergroupassociation
try {
    $Result = Search-FogLdapgroupusergroupassociation -Item $Item -Start $Start -Length $Length -Expand $Expand
} catch {
    Write-Host ("Exception occurred when calling Search-FogLdapgroupusergroupassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
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

[**ListLdapgroupusergroupassociation200Response**](ListLdapgroupusergroupassociation200Response.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

<a id="Update-FogLdapgroupusergroupassociation"></a>
# **Update-FogLdapgroupusergroupassociation**
> Ldapgroupusergroupassociation Update-FogLdapgroupusergroupassociation<br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Id] <Int32><br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-Ldapgroupusergroupassociation] <PSCustomObject><br>

Update a ldapgroupusergroupassociation

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
$Ldapgroupusergroupassociation = Initialize-Ldapgroupusergroupassociation -Id "MyId" -Name "MyName" -LdapgroupID "MyLdapgroupID" -UsergroupID "MyUsergroupID" # Ldapgroupusergroupassociation | 

# Update a ldapgroupusergroupassociation
try {
    $Result = Update-FogLdapgroupusergroupassociation -Id $Id -Ldapgroupusergroupassociation $Ldapgroupusergroupassociation
} catch {
    Write-Host ("Exception occurred when calling Update-FogLdapgroupusergroupassociation: {0}" -f ($_.ErrorDetails | ConvertFrom-Json))
    Write-Host ("Response headers: {0}" -f ($_.Exception.Response.Headers | ConvertTo-Json))
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **Id** | **Int32**|  | 
 **Ldapgroupusergroupassociation** | [**Ldapgroupusergroupassociation**](Ldapgroupusergroupassociation.md)|  | 

### Return type

[**Ldapgroupusergroupassociation**](Ldapgroupusergroupassociation.md) (PSCustomObject)

### Authorization

[basicAuth](../README.md#basicAuth), [fogApiToken](../README.md#fogApiToken), [bearerAuth](../README.md#bearerAuth), [fogUserToken](../README.md#fogUserToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

