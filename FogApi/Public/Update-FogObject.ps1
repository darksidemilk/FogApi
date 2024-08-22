function Update-FogObject {
<#
.SYNOPSIS
Update/patch/edit api calls

.DESCRIPTION
Runs update calls to the api

.EXAMPLE
$h = get-foghost; $h.ADUser = 'ldapBind'; Update-FogObject -type object -coreObject host -jsonData ($h | select-object aduser | ConvertTo-Json -Compress) -IDofObject $h.id -Verbose

Will update the ADUser field on the current host to be 'ldapbind' Note that when you update a host, you should not include the name field in the json if you are not changing the name.
You can also set other fields on the local $h object and update all changed fields excluding an unchanged name by using $h | select-object -excludeproperty name

.PARAMETER type
the type of fog object

.PARAMETER jsonData
the json data string. You can use convertto-json to pass powershell objects in

.PARAMETER IDofObject
The ID of the object

.PARAMETER uri
The explicit uri to use if you run into issues, the issues that caused the need for this originally have been resolved, but kept it for safety

.NOTES
If you are updating a fog host object, and your json includes the name of the host, but that name isn't changing, you'll get an error. You should omit the name from the json in such updates
i.e. if your fog host name is 'computer1' and you pass in a json string link {"name":"computer1","ADUser":"ldapBind"} you will get an error, but if the name is changing or you omit it, it will work without issue. This only affects the name field
#>
    [CmdletBinding()]
    [Alias('Set-FogObject')]
    param (
        # The type of object being requested
        [Parameter(Position=0)]
        [ValidateSet("object")]
        [string]$type,
        # The json data for the body of the request
        [Parameter(Position=2)]
        [Object]$jsonData,
        # The id of the object to remove
        [Parameter(Position=3)]
        [string]$IDofObject,
        [Parameter(Position=4)]
        [string]$uri
    )

    DynamicParam { $paramDict = Set-DynamicParams $type; return $paramDict; }

    process {
        $paramDict | ForEach-Object { New-Variable -Name $_.Keys -Value $($_.Values.Value);}
        Write-Verbose "Building uri and api call";
        if([string]::IsNullOrEmpty($uri)) {
            $uri = "$CoreObject/$IDofObject/edit";
        }

        $apiInvoke = @{
            uriPath=$uri;
            Method="PUT";
            jsonData=$jsonData;
        }
        $result = Invoke-FogApi @apiInvoke;
        return $result;
    }

}
