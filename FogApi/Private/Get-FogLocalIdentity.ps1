function Get-FogLocalIdentity {
    <#
    .SYNOPSIS
    Gets the identifying details of the machine this command is running on

    .DESCRIPTION
    Returns the uuid, primary mac address and hostname of the local machine, which are the three
    terms Get-FogHost matches against when it is called with no search parameters.

    This is the single place in the module that knows how to ask an operating system who it is.
    Keeping it here means the workflow functions above it stay platform agnostic, and means the
    windows and posix implementations can be fixed independently of everything that consumes them.

    On windows the details come from CIM. On linux and mac they come from the dmi tables under
    /sys/class/dmi/id and the interface list under /sys/class/net. Any value that cannot be
    determined is returned as $null rather than as an empty string, so callers can tell "unknown"
    apart from "known to be blank" - Get-FogHost relies on that distinction, because a null search
    term that is treated as a real one matches the wrong host.

    .EXAMPLE
    Get-FogLocalIdentity

    Returns the uuid, mac address and hostname of the current machine.

    Expected output:
    { "uuid": "4C4C4544-0032-3010-8043-B4C04F435931", "hostName": "MeowMachine" }

    .NOTES
    The bogus 12345678-9012-3456-7890-abcdefabcdef uuid is a known placeholder some vendors ship in
    smbios. When it is seen on windows the real value is pulled from the CIM qualifiers instead;
    on posix it is treated as unknown, since there is no equivalent second source.
    #>
    [CmdletBinding()]
    param ()

    process {
        $placeholderUuid = '12345678-9012-3456-7890-abcdefabcdef';
        $uuid = $null;
        $macAddress = $null;
        $macAddresses = @();
        $hostName = $null;

        try {
            $hostName = [System.Net.Dns]::GetHostName();
        } catch {
            Write-Verbose "could not resolve the local hostname: $($_.Exception.Message)";
        }

        if ($IsLinux -or $IsMacOS) {
            Write-Verbose 'collecting local identity from the posix dmi and net trees';

            #product_uuid is root readable only on most distros, so this can legitimately come back null
            $uuidPath = '/sys/class/dmi/id/product_uuid';
            if (Test-Path $uuidPath) {
                try {
                    $raw = (Get-Content $uuidPath -Raw -ea Stop).Trim();
                    if (-not [string]::IsNullOrWhiteSpace($raw) -and $raw -notmatch $placeholderUuid) {
                        $uuid = $raw;
                    }
                } catch {
                    Write-Verbose "could not read $uuidPath (usually needs root): $($_.Exception.Message)";
                }
            } else {
                Write-Verbose "$uuidPath is not present on this system";
            }

            #skip loopback and the usual virtual interfaces, and skip anything that is not up
            try {
                $macAddresses = @(
                    Get-ChildItem '/sys/class/net' -ea Stop |
                        Where-Object { $_.Name -notmatch '^(lo|docker|veth|br-|virbr|tun|tap)' } |
                        ForEach-Object {
                            $addrFile = Join-Path $_.FullName 'address';
                            $operFile = Join-Path $_.FullName 'operstate';
                            if (Test-Path $addrFile) {
                                $addr = (Get-Content $addrFile -Raw -ea 0).Trim();
                                $oper = if (Test-Path $operFile) { (Get-Content $operFile -Raw -ea 0).Trim() } else { 'unknown' };
                                if (-not [string]::IsNullOrWhiteSpace($addr) -and $addr -ne '00:00:00:00:00:00') {
                                    [PSCustomObject]@{ name = $_.Name; mac = $addr.ToUpper(); operstate = $oper };
                                }
                            }
                        }
                );
            } catch {
                Write-Verbose "could not enumerate /sys/class/net: $($_.Exception.Message)";
            }
            $up = @($macAddresses | Where-Object operstate -eq 'up');
            $macAddress = if ($up.Count -gt 0) { $up[0].mac } elseif ($macAddresses.Count -gt 0) { $macAddresses[0].mac } else { $null };
            $macAddresses = @($macAddresses.mac);
        } else {
            Write-Verbose 'collecting local identity from CIM';
            $compSys = $null;
            try {
                $compSys = Get-CimInstance -ClassName win32_computersystemproduct -ea Stop;
            } catch {
                #Get-WmiObject only exists on windows powershell 5.1, it was removed in pwsh 6+,
                #so only reach for it when it is actually there
                if (Get-Command Get-WmiObject -ea 0) {
                    $compSys = (Get-WmiObject Win32_ComputerSystemProduct);
                } else {
                    Write-Verbose "could not read win32_computersystemproduct: $($_.Exception.Message)";
                }
            }
            if ($null -ne $compSys) {
                if ($compSys.UUID -notmatch $placeholderUuid) {
                    $uuid = $compSys.UUID;
                } else {
                    $uuid = ($compSys.Qualifiers | Where-Object Name -match 'UUID' | Select-Object -ExpandProperty Value);
                }
            }

            $make = $null;
            try {
                $make = Get-CimInstance -classname win32_computersystem -ea Stop | Select-Object -ExpandProperty manufacturer;
            } catch {
                Write-Verbose "could not read win32_computersystem: $($_.Exception.Message)";
            }
            try {
                $adapters = Get-NetAdapter -ea Stop | Where-Object Status -eq 'up';
                if (($make) -notmatch 'vmware') {
                    $adapters = $adapters | Where-Object Name -notmatch 'VMware';
                }
                $macAddresses = @($adapters | Select-Object -expand MacAddress | ForEach-Object { $_.Replace('-',':') });
                $macAddress = $macAddresses | Select-Object -first 1;
            } catch {
                Write-Verbose "could not enumerate network adapters: $($_.Exception.Message)";
            }
        }

        if ([string]::IsNullOrWhiteSpace($uuid)) { $uuid = $null; }
        if ([string]::IsNullOrWhiteSpace($macAddress)) { $macAddress = $null; }
        if ([string]::IsNullOrWhiteSpace($hostName)) { $hostName = $null; }

        Write-Verbose "local identity is uuid $uuid, mac $macAddress, hostname $hostName";
        return [PSCustomObject]@{
            uuid         = $uuid;
            macAddress   = $macAddress;
            macAddresses = $macAddresses;
            hostName     = $hostName;
        };
    }

}
