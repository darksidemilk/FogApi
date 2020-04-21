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
        [switch]$static
    )
    
    begin {
        $fogLog = 'C:\fog.log';
    }
    
    process {
        if (!$static) {
            "Starting dynamic fog log in new window, Hit Ctrl+C on new window or close it to exit dynamic fog log" | Out-Host;
            Start-Process Powershell.exe -ArgumentList "-Command `"Get-Content $fogLog -Wait`"";
        }
        else {
            Get-Content $fogLog;
        }
    }
    
    end {
        return;
    }

}
