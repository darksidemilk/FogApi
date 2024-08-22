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

    .EXAMPLE
    Get-FogObject -type object -coreObject host

    This will get all hosts from the fog server.
    This will get all the hosts.

    
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
        [string]$IDofObject
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
                if ($null -eq $IDofObject -OR $IDofObject -eq "") {
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
        Write-Verbose "uri for get is $uri";
        $apiInvoke = @{
            uriPath=$uri;
            Method="GET";
            jsonData=$jsonData;
        }
        if ($null -eq $apiInvoke.jsonData -OR $apiInvoke.jsonData -eq "") {
            $apiInvoke.Remove("jsonData");
        }
        $result = Invoke-FogApi @apiInvoke;
        #if the api call wasn't for a specific object, convert the output to use the data property added in fog 1.6
        if (!$IDofObject) {
            $result = Add-FogResultData $result;
        }
        return $result;
    }
    

}
