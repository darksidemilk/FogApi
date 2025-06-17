function Test-StringNotNullOrEmpty {
    <#
    .SYNOPSIS
    Returns true if passed in object is a string that is not null, empty, or whitespace
    
    .DESCRIPTION
    Uses built in string functions to test if a given string is null, empty or whitespace
    if it is not any of these things and has valid content, this returns true otherwise false
    
    .PARAMETER str
    String to test
    
    .EXAMPLE
    Test-StringNotNullOrEmpty "An example"

    Will return true as it is a valid string with content

    .EXAMPLE
    $s = ""; Test-StringNotNullOrEmpty $s;

    Will return false as this is an empty string.

    .EXAMPLE
    $str = " "; $str | Test-StringNotNullOrEmpty

    Will return false as this string is just whitespace

    
    .NOTES
    Meant to simplify input validation tests as test-string $param or $value | test-string is easier to type in an if statement than
    doing [string]::isnullorempty($str) along with [string]::isnullorwhitespace($str)

    #>
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline=$true)]
        $str
    )
    
    
    process {
        $valid = $false;
        if ($null -eq $str) {
            $isString = $false;
        } elseif (($str.gettype().name) -eq "String") {
            $isString = $true;
        } else {
            $isString = $false;
        }
        if ($isString) {
            $empty = [string]::IsNullOrEmpty($str)
            $whitespace = [string]::IsNullOrWhiteSpace($str)
        } else {
            Write-Warning "input $($str) is not a string object it is of type $($str.gettype().name), cannot test for empty or whitespace, will test for null only";
            if ($null -eq $str) {
                "This is not a string, but it is null, returning false";
                $valid = $false;
            } else {
                "This is not a string, but it is not null, returning true";
                $valid = $true;
            }
        }
        
        if (!$empty -and !$whitespace -and $isString) {
            $valid = $True;
        }
        return $valid;
        
    }
    
}