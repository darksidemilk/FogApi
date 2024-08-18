function Get-FogVersion {
    [CmdletBinding()]
    param (
        
    )
    
    
    process {
        return Invoke-FogApi -uriPath "system/info" -Method Get;
    }
    
}