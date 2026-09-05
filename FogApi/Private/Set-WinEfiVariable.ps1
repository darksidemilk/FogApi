function Set-WinEfiVariable {
<#
.SYNOPSIS
Writes or deletes a uefi variable in the EFI global namespace

.DESCRIPTION
Writes raw bytes to a firmware variable through SetFirmwareEnvironmentVariableW.
Passing an empty byte array deletes the variable, which is how the win32 api
expresses removal, there is no separate delete call.

Returns true on success, false otherwise, and writes the win32 reason to the
verbose stream.

.PARAMETER name
The uefi variable name, for example BootNext

.PARAMETER value
The bytes to store. An empty array deletes the variable.

.PARAMETER namespaceGuid
The variable namespace guid in braces. Defaults to the EFI global namespace
{8be4df61-93ca-11d2-aa0d-00e098032b8c}

.EXAMPLE
Set-WinEfiVariable -name BootNext -value ([BitConverter]::GetBytes([uint16]3))

Arms boot option 0003 for the next boot only

.NOTES
Private helper. Writing firmware variables needs SeSystemEnvironmentPrivilege
enabled, so an elevated or SYSTEM token; see Initialize-WinEfiApi.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [string]$name,
        [Parameter(Position=1)]
        [byte[]]$value = @(),
        [string]$namespaceGuid = '{8be4df61-93ca-11d2-aa0d-00e098032b8c}'
    )

    process {
        if (-not (Initialize-WinEfiApi)) { return $false; }

        $ok = [FogApi.WinEfi]::SetFirmwareEnvironmentVariableW($name, $namespaceGuid, $value, $value.Length);
        if (-not $ok) {
            $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error();
            switch ($err) {
                1 { Write-Warning "No uefi boot manager on this machine (bios/csm), cannot write $name" }
                1314 { Write-Warning "Writing $name needs SeSystemEnvironmentPrivilege enabled, run elevated or as SYSTEM" }
                default { Write-Warning "Writing firmware variable $name failed with win32 error $err" }
            }
            return $false;
        }
        return $true;
    }
}
