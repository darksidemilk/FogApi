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
    $result = Invoke-FogApi @apiInvoke;$result = Add-FogResultData $result;
    
    If using fog 1.5.x will add $results.data with the value of the results property, $result.tasks if fog 1.6 will do nothing as $result.data already exists
    
    #>
    [CmdletBinding()]
    param ( 
        [Parameter()]
        $result
    )
    
    process {
        #test if result has data property
        if ($null -eq ($result | Get-Member -Name data)) {
            #result doesn't have data property
            $property = ($result | get-member -MemberType NoteProperty | Where-Object name -notmatch 'count').name
            $newResult = [PSCustomObject]@{
                count = $result.count;
                data = $result.$property;
                $property = $result.$property;
            }
            $result = $newResult;
            # $result | Add-Member -MemberType NoteProperty -Name data -Value $result.$property -Force
        }
        return $result;
    }
    
    
}