function Get-FogVersion {
    <#
    .SYNOPSIS
    Gets the version of FOG
    
    .DESCRIPTION
    Only works for 1.6 beta and above, 1.5.x is identified as 1.5.10 if null is returned
    
    .EXAMPLE
    Get-FogVersion;

    Will return the full version string
    
    #>
    [CmdletBinding()]
    param (
        
    )
    
    
    process {
        $info = (Invoke-FogApi -uriPath "system/info" -Method Get -ea 0)
        if ($null -ne $info) {
            $versionStr = $info.version;
        } 
        if ([string]::IsNullOrEmpty($versionStr)) {
            "Error finding version on system/info pass, getting version from getversion.php" | out-host;
            $versionStr = (Invoke-FogApi -uriPath "service/getversion.php" -Method Get )
        }
        return $versionStr
    }
    
}