function Disable-FogApiHTTPS {
    <#
    .SYNOPSIS
    Enforce http in the url used in all api calls
    
    .DESCRIPTION
    Prepends http to the fogserver property of fog server settings

    .EXAMPLE
    Disable-FogApiHTTPS

    This example will enforce http in the url used in all api calls by prepending http to the fogserver property of fog server settings
    
    #>
    [CmdletBinding()]
    param (
        
    )
    
    process {
        $fogServer = (Get-FogServerSettings).fogserver;
        if ($fogServer -notlike "http://*") {
            if ($fogServer -like "https://*") {
                $fogServer = $fogServer.replace("https://","http://")
            } else {
                $fogServer = "http://$fogserver"
            }
            $result = Set-FogServerSettings -fogServer $fogServer;
            Write-Verbose "result is $($result | out-string)";
        } else {
            Write-Verbose "Http already enabled!"
            # $result = $true;
        }
        return $fogserver;
    }
    
}