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
        } elseif ($script:IsPosix) {
            #on a linux fog server the logs live under /var/log/fog, and the client writes to
            #/var/log/fog.log. This used to fall through to the windows paths and then return
            #one of them regardless, handing the caller a path that does not exist here
            $fogLog = ('/var/log/fog.log', '/var/log/fog/fog.log' | Where-Object { Test-Path $_ } | Select-Object -First 1);
        } else {
            $fogLog = 'C:\fog.log';
            if (!(Test-Path $fogLog)) {
                $fogLog = "C:\ProgramData\fog\fog.log"
            }
        }
        if ([string]::IsNullOrWhiteSpace($fogLog) -or !(Test-Path $fogLog)) {
            Write-Warning "No fog log was found$(if ($fogLog) { " at $fogLog" }). Pass -userFogLog for the per user client log, or check that the fog client or server is installed on this machine.";
            return $null;
        }
        if (!$static) {
            "Starting dynamic fog log in new window, Hit Ctrl+C on new window or close it to exit dynamic fog log" | Out-Host;
            #pwsh on linux and mac, powershell.exe does not exist there
            $shell = if ($script:IsPosix) { 'pwsh' } else { 'Powershell.exe' };
            Start-Process $shell -ArgumentList "-Command `"Get-Content $fogLog -Wait`"";
        }
        else {
            Get-Content $fogLog;
        }
        return $fogLog;
    }

}
