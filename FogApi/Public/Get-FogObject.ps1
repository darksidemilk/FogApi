function Get-FogObject {
<#
    .SYNOPSIS
    Gets a fog object via the api

    .DESCRIPTION
    Gets a object, objecactivetasktype, or performs a search via the api
    Once a type has been selected the next parameter is dynamically added
    along with a tab completable list of options. i.e type of object will add the coreobject parameter 
    Note that getting a fog object is similar but different from searching aka finding a fog object. Use Find-FogObject for searching

    .PARAMETER type
    the type of object to get can be "objectactivetasktype" or "object", object is for most items, the other is for getting active tasks

    .PARAMETER jsonData
    the json data in json string format if required

    .PARAMETER IDofObject
    the specific id of the object to get

    .PARAMETER First
    only return the first n objects. Stops requesting further pages once satisfied

    .PARAMETER Skip
    skip the first n objects, i.e. start paging at this offset

    .PARAMETER PageSize
    how many rows to request per api call when auto paging. Defaults to 1000

    .PARAMETER NoAutoPage
    make a single request and return the raw api envelope untouched instead of auto paging

    .PARAMETER Filter
    Server side column filter, as a hashtable of field/value pairs ANDed together.
    An array value matches any of its parts. Only fields the class declares are
    accepted; the server answers 400 naming the key otherwise, and refuses
    credential fields outright.

    Requires FOG 1.6.0-beta.3894 or later, the release that began advertising
    ?filter= in its OpenAPI document. Earlier servers ignore the parameter and
    return the whole list, so check Test-FogVerAbove1dot6 and the server version
    if you need to be certain a filter was applied rather than assumed.

    .PARAMETER subPath
    one of the cheap per-class sub-routes: count, names or ids. FOG 1.6 only.
    These are unpaged and are returned exactly as the server sends them, because none of them
    carries a list envelope: count answers {"total":N}, names a bare array of id/name pairs,
    and ids a bare array of integers. names and ids have no LIMIT applied server side at all,
    which makes them the cheap way to enumerate a large table when you only need identifiers.
    Cannot be combined with IDofObject - these are routes on the class, not on one object.
    FOG 1.5 does not serve any of them and will answer with an error.

    .EXAMPLE
    Get-FogObject -type object -coreObject host

    This will get all hosts from the fog server.
    This will get all the hosts.

    Expected output:
    { "count": 1, "data": [ { "name": "MeowMachine", "id": 42 } ] }

    .EXAMPLE
    Get-FogObject -type objectactivetasktype -coreActiveTaskObject task

    This will get all the active tasks from the fog server which is in the objectactivetasktype type of object.

    .EXAMPLE
    Get-FogObject -type object -coreObject host -First 5

    This will get only the first 5 hosts, stopping once it has them instead of paging through every host.

    Expected output:
    { "count": 1, "data": [ { "name": "MeowMachine", "id": 42 } ] }

    .EXAMPLE
    Get-FogObject -type object -coreObject host -subPath count

    Asks the server how many hosts there are without transferring any of them.
    Reports the true filtered total and ignores paging.

    Expected output:
    { "total": 1 }

    .EXAMPLE
    Get-FogObject -type object -coreObject host -subPath names

    Returns id and name pairs only. Unpaged and uncapped server side, so this is the cheap
    way to enumerate a large table when the other fields are not needed.

    Expected output:
    [ { "id": 42, "name": "MeowMachine" } ]
    .EXAMPLE
    Get-FogObject -type object -coreObject tasklog -Filter @{ hostID = 42 }

    Returns only the taskLog rows for host 42, filtered by the server rather than
    after the fact. Expected output:
    { "id": 1, "hostID": 42, "hostName": "MeowMachine", "imageName": "Win-10-21H2" }

    .EXAMPLE
    Get-FogObject -type object -coreObject tasklog -Filter @{ hostID = 42 } -subPath count

    Returns how many taskLog rows host 42 has, without transferring any of them.
    The filter applies to count, names and ids as well as to the list itself.
    Expected output:
    { "total": 3 }


    .NOTES
    FOG 1.6 caps any unbounded list request at 10000 rows (MAX_ROWS), so a plain list call silently
    returned a partial result. This function now always sends explicit start/length paging params and
    follows the servers nextUrl until it is null, so every object is returned.
    FOG 1.5 has no paging and ignores the params, returning its whole list in one response, in which
    case First/Skip are applied client side instead.

#>

    [CmdletBinding()]
    param (
        # The type of object being requested
        [Parameter(Position=0)]
        [ValidateSet("objectactivetasktype","object")]
        [string]$type,
        # The json data for the body of the request
        [Parameter(Position=2)]
        [Object]$jsonData,
        # The id of the object to get
        [Parameter(Position=3)]
        [string]$IDofObject,
        [Parameter()]
        [int]$First,
        [Parameter()]
        [int]$Skip,
        [Parameter()]
        [int]$PageSize = 1000,
        [Parameter()]
        [switch]$NoAutoPage,
        # The cheap per-class sub-routes. A ValidateSet rather than a free
        # string on purpose: this is not a general escape hatch for arbitrary
        # paths -- Get-FogPagedResult -uriPath is that -- it is the three
        # sub-routes that belong to a class alongside its list.
        [Parameter()]
        [ValidateSet('count','names','ids')]
        [string]$subPath,
        # Server side column filter. A hashtable rather than a raw string
        # because the wire format is a query string nested inside one query
        # parameter, so it has to be encoded as a unit -- see
        # ConvertTo-FogFilterQuery. FOG 1.6.0-beta.3894 and later; earlier
        # 1.6 servers and all of 1.5 ignore it and return the unfiltered list,
        # which is why this does not silently become the only way to filter.
        [Parameter()]
        [hashtable]$Filter
    )

    DynamicParam { $paramDict = Set-DynamicParams $type; return $paramDict;}
    
    process {
        $paramDict | ForEach-Object { New-Variable -Name $_.Keys -Value $($_.Values.Value);}
        # $paramDict;
        Write-Verbose "Building uri and api call for $($paramDict.keys) $($paramDict.values.value)";
        switch ($type) {
            objectactivetasktype {
                $uri = "$coreActiveTaskObject/current";
            }
            object {
                if (-not [string]::IsNullOrEmpty($subPath)) {
                    if (-not [string]::IsNullOrEmpty($IDofObject)) {
                        throw "Get-FogObject: -subPath and -IDofObject are mutually exclusive. '$subPath' is a route on the class, not on one object.";
                    }
                    $uri = "$coreObject/$subPath";
                }
                elseif ($null -eq $IDofObject -OR $IDofObject -eq "") {
                    $uri = "$coreObject";
                }
                else {
                    $uri = "$coreObject/$IDofObject";
                }
            }
            # search {
            #     if ($coreObject) {
            #         $uri = "$coreObject/$type/$stringToSearch";
            #     } else {
            #         $uri = "$type/$stringToSearch"
            #     }
            # }
        }
        # Only list-shaped calls take a filter. /{class}/{id} addresses one
        # row and /{class}/current is the active-task route -- neither reads
        # the parameter, so sending it would look supported and do nothing.
        if ($null -ne $Filter -AND $Filter.Keys.Count -gt 0) {
            if ($type -ne 'object') {
                throw "Get-FogObject: -Filter applies to object lists, not to '$type'.";
            }
            if (-not [string]::IsNullOrEmpty($IDofObject)) {
                throw "Get-FogObject: -Filter and -IDofObject are mutually exclusive. A filter selects rows from the class; an id already names one.";
            }
            # ${uri} braced deliberately: `?` is a legal character in an
            # unbraced PowerShell variable name, so "$uri?..." parses as the
            # variable `uri?`, which does not exist -- it expands to empty and
            # the class name silently vanishes from the path.
            $uri = "${uri}?$(ConvertTo-FogFilterQuery -Filter $Filter)";
        }
        Write-Verbose "uri for get is $uri";
        $apiInvoke = @{
            uriPath=$uri;
            Method="GET";
            jsonData=$jsonData;
        }
        if ($null -eq $apiInvoke.jsonData -OR $apiInvoke.jsonData -eq "") {
            $apiInvoke.Remove("jsonData");
        }

        #only a plain list call can be paged, a call for one specific object cannot
        #the count/names/ids sub-routes are not paged either - see below
        [bool]$isListCall = ($type -eq 'object') -AND (!$IDofObject) -AND ([string]::IsNullOrEmpty($subPath));

        if (!$isListCall -OR $NoAutoPage) {
            $result = Invoke-FogApi @apiInvoke;
            # The sub-routes are returned exactly as the server sent them.
            # None of them carries a list envelope to normalise: count answers
            # {"total":N}, names a bare array of {id,name}, ids a bare array of
            # integers. Add-FogResultData exists to paper over the 1.5-vs-1.6
            # LIST envelope difference, and these three do not exist on 1.5 at
            # all, so there is nothing for it to reconcile and running it would
            # only wrap a plain array in a shape the caller did not ask for.
            if (!$IDofObject -AND [string]::IsNullOrEmpty($subPath)) {
                #if the api call wasn't for a specific object, convert the output to use the data property added in fog 1.6
                $result = Add-FogResultData $result;
            }
            return $result;
        }

        $pagedArgs = @{
            uriPath = $uri;
            Method = 'GET';
            First = $First;
            Skip = $Skip;
            PageSize = $PageSize;
        }
        if (-not [string]::IsNullOrEmpty($jsonData)) { $pagedArgs.jsonData = $jsonData; }
        return (Get-FogPagedResult @pagedArgs);
    }
    

}
