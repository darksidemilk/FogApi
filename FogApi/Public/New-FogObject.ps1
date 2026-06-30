function New-FogObject {
<#
.SYNOPSIS
Create a new fog object with the api

.DESCRIPTION
creates a new object such as a host or task

.PARAMETER type
the type of api object, either objecttasktype or object

.PARAMETER jsonData
json data in json string for api call

.PARAMETER IDofObject
the id of the object

.EXAMPLE
$hostID = 1234; $json = (@{"taskTypeID"='12';"deploySnapins"="-1";} | ConvertTo-Json); $result = New-FogObject -type objecttasktype -coreTaskObject host -jsonData $json -IDofObject "$hostID"; $result;

Would create a new fog object of a start all snapins task. 

#>

    [CmdletBinding()]
    [Alias('Add-FogObject')]
    param (
        # The type of object being requested
        [Parameter(Position=0)]
        [ValidateSet("objecttasktype","object")]
        [string]
        $type,
        # The json data for the body of the request
        [Parameter(Position=2)]
        [Object]$jsonData,
        # The id of the object when creating a new task
        [Parameter(Position=3)]
        [string]$IDofObject
    )

    DynamicParam { $paramDict = Set-DynamicParams $type; return $paramDict;}

    process {
        $paramDict | ForEach-Object { New-Variable -Name $_.Keys -Value $($_.Values.Value);}
        Write-Verbose "Building uri and api call";
        switch ($type) {
            objecttasktype {
                $uri = "$CoreTaskObject/$IDofObject/task";
            }
            object {
                $uri = "$CoreObject";
            }
        }
        $apiInvoke = @{
            uriPath=$uri;
            Method="POST";
            jsonData=$jsonData;
        }
        $result = Invoke-FogApi @apiInvoke;
        return $result;
    }

}
