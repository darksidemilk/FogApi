function Add-FogResultData {
    <#
    .SYNOPSIS
    This tests the result of invoke-fogapi to see if its the newer (fog 1.6) version of the api that uses the data property, or if it uses the old specified property
    If the data property is missing it is added
    
    .DESCRIPTION
    If the data property of the given result doesn't exist it will find the correct data property name and add the data property with the value of the old api path property
    This was created for compatibility between fog 1.5 and fog 1.6. If you are on fog 1.5.x the old property will still exist in the result
    
    .PARAMETER result
    Should be the output of a invoke-fogapi that has properties from the api result

    .EXAMPLE
    $raw = [PSCustomObject]@{ count = 1; tasks = @([PSCustomObject]@{ id = 1 }) }; Add-FogResultData $raw

    If using fog 1.5.x will add $result.data with the value of the results property, $result.tasks if fog 1.6 will do nothing as $result.data already exists

    Expected output:
    { "data": [ { "id": 1 } ] }

    #>
    [CmdletBinding()]
    param ( 
        [Parameter()]
        $result
    )
    
    process {
        #test if result has data property
        if ($null -ne $result) {
            if ($null -eq ($result | Get-Member -Name data -ea 0)) {
                #result doesn't have data property
                $property = ($result | get-member -MemberType NoteProperty | Where-Object name -notmatch 'count').name
                if ($property -is [array]) {
                    #more than one candidate property, prefer the one holding a collection as that is the row set
                    $arrayProp = $property | Where-Object { $result.$_ -is [array] } | Select-Object -First 1;
                    $property = if ($null -ne $arrayProp) { $arrayProp } else { $property[0] };
                    Write-Verbose "multiple non count properties found, using $property as the data property";
                }
                $newResult = [PSCustomObject]@{
                    count = $result.count;
                    data = $result.$property;
                    $property = $result.$property;
                }
                $result = $newResult;
                # $result | Add-Member -MemberType NoteProperty -Name data -Value $result.$property -Force
            }
        }
        return $result;
    }
    
    
}