function Enable-FogApiHTTPS {
    <#
    .SYNOPSIS
    Enforce https in the url used in all api calls
    
    .DESCRIPTION
    Prepends https to the fogserver property of fog server settings
    
    #>
    [CmdletBinding()]
    param (
        
    )
    
    process {
        $fogServer = (Get-FogServerSettings).fogserver;
        if ($fogServer -notlike "https://*") {
            if ($fogServer -like "http://*") {
                $fogServer = $fogServer.replace("http://","https://")
            } else {
                $fogServer = "https://$fogserver"
            }
            $result = Set-FogServerSettings -fogServer $fogServer;
            Write-Verbose "result is $($result | out-string)";
        } else {
            Write-Verbose "Https already enabled!"
            # $result = $true;
        }
        return $fogserver;
    }
    
}