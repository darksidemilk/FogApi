function Find-FogObject {
<#
    .SYNOPSIS
    Searches for a fog object (of specified type, or searches all types [fog 1.6 only]) via the api
    Note that it will search all fields for the search string, not just the name.

    .DESCRIPTION
    Searches for a given string within a given coreobject type
    Once a type has been selected the next parameter is dynamically added along with a tab completable list of options. i.e type of object will add the coreobject parameter 
    The stringToSearch you provide will be searched for in that object, just like if you were in the web gui searching for a host, group, etc. 
    If you are using fog 1.6, you can set the $coreObject variable to 'unisearch' and it will do a universal search

    .PARAMETER type
    Defaults to 'search' and can only be 'search', has to be set for the dynamic coreObject param to populate

    .PARAMETER stringToSearch
    The string to search for in the given object type or for universal search.

    .EXAMPLE
    Find-FogObject -type search -coreObject host -stringToSearch "computerName"

    This will find and return all host objects that have 'computername' in any field.

    .EXAMPLE
    $result = Find-FogObject -type search -coreObject group -stringToSearch "IT"'; $result.data | Where-Object name -match "IT";
    
    This will find all groups with IT in any field. Then filter to where IT is in the name field and display that list
#>

    [CmdletBinding()]
    param (
        # The type of object being requested, should be search
        [Parameter(Position=0)]
        [ValidateSet("search")]
        [string]$type = "search",
        # The id of the object to get
        [Parameter(Position=2)]
        [string]$stringToSearch
    )

    DynamicParam { $paramDict = Set-DynamicParams $type; return $paramDict;}

    begin {
        $paramDict | ForEach-Object { New-Variable -Name $_.Keys -Value $($_.Values.Value);}
        # $paramDict;
        Write-Verbose "Building uri and api call for $($paramDict.keys) $($paramDict.values.value)";
        switch ($type) {
            search {
                if ($coreObject -ne "unisearch") {
                    $uri = "$coreObject/$type/$stringToSearch";
                } else {
                    $uri = "$type/$stringToSearch"
                }
            }
        }
        Write-Verbose "uri for get is $uri";
        $apiInvoke = @{
            uriPath=$uri;
            Method="GET";
        }
    }

    process {
        $result = Invoke-FogApi @apiInvoke;
    }
    
    end {
        #convert the output to use the data property added in fog 1.6
        $result = Add-FogResultData $result;
        return $result;
    }

}
