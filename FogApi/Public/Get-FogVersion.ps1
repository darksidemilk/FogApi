function Get-FogVersion {
    <#
    .SYNOPSIS
    Gets the version of FOG
    
    .DESCRIPTION
    Only works for 1.6 beta and above, 1.5.x is identified as 1.5.10 if null is returned
    
    .EXAMPLE
    Get-FogVersion;

    Will return the full version string
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        
    )
    
    
    process {
        $versionStr = (Invoke-FogApi -uriPath "system/info" -Method Get).version;
        if ([string]::IsNullOrEmpty($versionStr)) {
            return "1.5.10";
        }
    }
    
}