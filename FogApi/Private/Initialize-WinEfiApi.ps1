function Initialize-WinEfiApi {
<#
.SYNOPSIS
Loads the Win32 firmware variable api and enables the privilege its calls require

.DESCRIPTION
Adds the [FogApi.WinEfi] p/invoke type for GetFirmwareEnvironmentVariableW and
SetFirmwareEnvironmentVariableW, then enables SeSystemEnvironmentPrivilege in the
current process token.

Holding a privilege and having it enabled are two different things. A token carries
most privileges disabled, and both the read and the write fail with
ERROR_PRIVILEGE_NOT_HELD (1314) until AdjustTokenPrivileges switches this one on.
LocalSystem holds it disabled like everything else, so a service that skips this step
sees 1314 and looks exactly like a machine with no uefi.

Returns true when the api is usable, false on linux/macos.

.EXAMPLE
Initialize-WinEfiApi

Loads the type and enables the privilege, returning true on windows

.NOTES
Private helper for Get-WinEfiVariable and Set-WinEfiVariable.
#>
    [CmdletBinding()]
    param ()

    process {
        if ($IsLinux -or $IsMacOS) {
            Write-Verbose "Firmware variables are only readable on windows";
            return $false;
        }
        if (-not ('FogApi.WinEfi' -as [type])) {
            Add-Type -Namespace FogApi -Name WinEfi -MemberDefinition @'
[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
public static extern uint GetFirmwareEnvironmentVariableW(
    string lpName, string lpGuid, byte[] pBuffer, uint nSize);

[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool SetFirmwareEnvironmentVariableW(
    string lpName, string lpGuid, byte[] pValue, uint nSize);

[DllImport("advapi32.dll", SetLastError=true)]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool OpenProcessToken(IntPtr h, uint acc, out IntPtr tok);

[DllImport("advapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool LookupPrivilegeValueW(string sys, string name, out long luid);

[DllImport("advapi32.dll", SetLastError=true)]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool AdjustTokenPrivileges(IntPtr tok, bool dis,
    ref TOKEN_PRIVILEGES newst, uint len, IntPtr prev, IntPtr ret);

[DllImport("kernel32.dll", SetLastError=true)]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool CloseHandle(IntPtr h);

// Pack=4 is load bearing. TOKEN_PRIVILEGES in C is a DWORD followed by a
// 4 byte aligned LUID_AND_ATTRIBUTES, but .net's default packing aligns the
// 8 byte Luid to offset 8 and inserts four bytes of padding. Windows then
// reads a garbage luid and AdjustTokenPrivileges reports
// ERROR_NOT_ALL_ASSIGNED, which reads exactly like "this token does not hold
// the privilege" and is not.
[StructLayout(LayoutKind.Sequential, Pack=4)]
public struct TOKEN_PRIVILEGES {
    public uint PrivilegeCount;
    public long Luid;
    public uint Attributes;
}
'@
        }

        # TOKEN_ADJUST_PRIVILEGES (0x20) | TOKEN_QUERY (0x8), and
        # SE_PRIVILEGE_ENABLED is 0x2.
        $tok = [IntPtr]::Zero;
        $proc = [Diagnostics.Process]::GetCurrentProcess().Handle;
        if (-not [FogApi.WinEfi]::OpenProcessToken($proc, 0x28, [ref]$tok)) {
            Write-Verbose "Could not open the process token, firmware calls will likely fail";
            return $true;
        }
        try {
            $luid = [long]0;
            if ([FogApi.WinEfi]::LookupPrivilegeValueW($null, 'SeSystemEnvironmentPrivilege', [ref]$luid)) {
                $tp = New-Object FogApi.WinEfi+TOKEN_PRIVILEGES;
                $tp.PrivilegeCount = 1;
                $tp.Luid = $luid;
                $tp.Attributes = 0x2;
                [void][FogApi.WinEfi]::AdjustTokenPrivileges($tok, $false, [ref]$tp, 0, [IntPtr]::Zero, [IntPtr]::Zero);
                # AdjustTokenPrivileges returns success even when it enabled
                # nothing; ERROR_NOT_ALL_ASSIGNED (1300) arrives as the last
                # error instead, which is the one way this call lies.
                $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error();
                if ($err -eq 1300) {
                    Write-Verbose "This process does not hold SeSystemEnvironmentPrivilege, firmware calls need an elevated/SYSTEM token";
                }
            }
        } finally {
            [void][FogApi.WinEfi]::CloseHandle($tok);
        }
        return $true;
    }
}
