function Get-FogLog {
<#
.SYNOPSIS
Get a auto updating fog log

.DESCRIPTION
For Windows
Uses get-content -wait to show a dynamic fog log or use -static to just see the current contents

.PARAMETER static
show the static contents of the fog log

.EXAMPLE
Get-FogLog

Will open a live display of the fog log as it is written to

.EXAMPLE
Get-FogLog -static

Will return the contents of the fog log as a string

#>

    [CmdletBinding()]
    param (
        [switch]$static,
        [switch]$userFogLog
    )
    
    process {
        if ($userFogLog) {
            $fogLog = "$home/.fog_user.log"
        } else {
            $fogLog = 'C:\fog.log';
            if (!Test-Path $fogLog) {
                $fogLog = C:\ProgramData\fog\fog.log
            }
        }
        if (!$static) {
            "Starting dynamic fog log in new window, Hit Ctrl+C on new window or close it to exit dynamic fog log" | Out-Host;
            Start-Process Powershell.exe -ArgumentList "-Command `"Get-Content $fogLog -Wait`"";
        }
        else {
            Get-Content $fogLog;
        }
        return $fogLog;
    }

}
