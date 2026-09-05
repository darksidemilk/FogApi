function Get-WinEfiVariable {
<#
.SYNOPSIS
Reads a uefi variable from the EFI global namespace and returns its raw bytes

.DESCRIPTION
Reads a variable such as BootOrder, BootNext or Boot0003 out of firmware through
GetFirmwareEnvironmentVariableW and returns a byte array, or null when the variable
does not exist or firmware cannot be reached.

Unlike linux's efivarfs there is no 4 byte attribute word on the windows api, so the
bytes returned here are the value itself.

.PARAMETER name
The uefi variable name, for example BootOrder, BootNext or Boot0003

.PARAMETER namespaceGuid
The variable namespace guid in braces. Defaults to the EFI global namespace
{8be4df61-93ca-11d2-aa0d-00e098032b8c}

.EXAMPLE
Get-WinEfiVariable BootOrder

Returns the raw bytes of the firmware boot order, a little endian uint16 per entry

.NOTES
Private helper. Needs an elevated or SYSTEM token; see Initialize-WinEfiApi.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [string]$name,
        [string]$namespaceGuid = '{8be4df61-93ca-11d2-aa0d-00e098032b8c}'
    )

    process {
        if (-not (Initialize-WinEfiApi)) { return $null; }

        # 8192 is comfortably above a BootOrder on a machine with many entries
        # and above any single load option. A short buffer reports
        # ERROR_INSUFFICIENT_BUFFER rather than silently truncating.
        $buffer = New-Object byte[] 8192;
        $read = [FogApi.WinEfi]::GetFirmwareEnvironmentVariableW($name, $namespaceGuid, $buffer, $buffer.Length);
        if ($read -eq 0) {
            $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error();
            switch ($err) {
                # ERROR_INVALID_FUNCTION is what a bios/csm machine returns:
                # there is no uefi here at all, which is a different thing from
                # a variable that is not set.
                1 { Write-Verbose "No uefi boot manager on this machine (bios/csm), cannot read $name" }
                1314 { Write-Verbose "Reading $name needs SeSystemEnvironmentPrivilege enabled, run elevated or as SYSTEM" }
                203 { Write-Verbose "Firmware variable $name is not set" }
                default { Write-Verbose "Reading $name failed with win32 error $err" }
            }
            return $null;
        }
        return $buffer[0..($read - 1)];
    }
}
