function Get-WinBcdPxeId {
    <#
    .SYNOPSIS
    Searches bcd firmware options for a given or model specific search string and returns the boot device guid 
    
    .DESCRIPTION
    Returns the bcd object guid of this machine's network boot entry.
    The id can be used with `bcdedit /set "{fwbootmgr}" displayorder $pxeID /addfirst` to be set as the first boot option in the computer's bios boot order

    It asks the firmware first. Get-WinNetBootOption identifies the network entry by its uefi
    device path, which states what an entry is, and this then looks up the guid bcdedit knows
    that same entry by, matching on the firmware's own description. So the description is used
    only to correlate two views of an entry already identified, never to work out what it is.

    The description searching below it is the original behaviour, kept as the fallback for the
    cases where the firmware variables cannot be read - an unelevated session, or a bios/csm
    machine with no uefi boot manager at all - and used whenever an explicit -searchString is
    given. It looks for the up ethernet adapter's interface description, then 'IPV4', 'Network',
    'LAN' and 'PXE' in turn, which works on most machines and quietly picks the wrong entry, or
    none, on the ones that name things differently.
    
    .PARAMETER searchString
    Optionatlly specify a search string, can be pxe related or try to find a different id from `bcdedit /enum firmware`

    .PARAMETER notBootMgr
    switch param to not return the main bootmgr entry if it is returned

    .EXAMPLE
    Get-WinBcdPxeId

    Will return the guid of the native pxe boot option if one is found.
    
    #>
    [CmdletBinding()]
    param (
        [string]$searchString,
        [switch]$notBootMgr
    )
    
    process {
        if ($IsLinux -or $IsMacOS) {
            Write-Warning "This is currently only implemented for windows"
            return $null;
        } else {
            # Ask the firmware itself first. An entry whose device path carries a
            # MAC/IPv4/IPv6 node IS a network boot entry, whatever the vendor
            # chose to call it, so this needs no search strings and cannot pick
            # the wrong one. Only when firmware variables are unreadable, or the
            # caller named a search string, does the original search below run.
            if (!(Test-StringNotNullOrEmpty $searchString)) {
                $netOption = (Get-WinNetBootOption | Select-Object -First 1);
                if ($null -ne $netOption) {
                    $exactID = (Get-WinBcdIdFromDescription -description $netOption.Description);
                    if ($null -ne $exactID) {
                        "pxeID found is $exactID full context is $($netOption | Out-String)" | Out-Host;
                        return $exactID;
                    }
                    Write-Verbose "Firmware holds $($netOption.BootVar) '$($netOption.Description)' but bcdedit does not list it, falling back to searching descriptions";
                } else {
                    Write-Verbose "Could not identify a network boot entry from the firmware variables, falling back to searching bcdedit descriptions";
                }
            }
            if (!(Test-StringNotNullOrEmpty $searchString)) {
                [object]$searchString = (Get-NetAdapter -ea 0 | Where-Object status -eq up | Where-Object name -match 'Ethernet')[0]
                $searchString2 = "IPV4"
                $searchString3 = "Network"
                $searchString4 = "LAN"
                $searchString5 = "PXE"
            }
            # $searchString;
            # pause;
            if ((Test-StringNotNullOrEmpty "$($searchString.InterfaceDescription)" -ea 0)) {
                #search for PXE string that doesn't match ipxe but does match the interface description of the first ethernet adapter that is currently up
                $searchString = $searchString.InterfaceDescription;
                Write-Verbose "Searching bcd firmware boot options for description that matches $searchString"
                $search = (bcdedit /enum firmware | Where-Object { $_ -notmatch 'ipxe'} | select-string $searchString -Context 3,0 -SimpleMatch -ea 0);
                Write-Verbose "Result of search: $($search | out-string)"
            } else {
                Write-Verbose "Searching bcd firmware boot options for description that matches $searchString"
                $search = (bcdedit /enum firmware | Where-Object { $_ -notmatch 'ipxe'} | select-string $searchString -Context 3,0 -ea 0);
                Write-Verbose "Result of search: $($search | out-string)"
            }
            if (($null -eq $search) -and ($null -ne $searchString2)) {
                
                #search for PXE string that doesn't match ipxe that might match 'ipv4'
                Write-Verbose "Searching bcd firmware boot options for description that matches $searchString2"
                $search2 = (bcdedit /enum firmware | Where-Object { $_ -notmatch 'ipxe'} | select-string $searchString2 -Context 3,0 -ea 0);
                Write-Verbose "Result of search: $($search2 | out-string)"
            }
            if (($null -eq $search) -and ($null -eq $search2) -and ($null -ne $searchString3)) {
                #search for PXE string that doesn't match ipxe that might match 'Network' (or 'EFI Network' on a surface go 2)
                Write-Verbose "Searching bcd firmware boot options for description that matches $searchString3"
                $search3 = (bcdedit /enum firmware | Where-Object { $_ -notmatch 'ipxe'} | select-string $searchString3 -Context 3,0 -ea 0);
                Write-Verbose "Result of search: $($search3 | out-string)"
            }
            if (($null -eq $search) -and ($null -eq $search2) -and ($null -eq $search3) -and ($null -ne $searchString4)) {
                #search for PXE string that doesn't match ipxe but does match 'LAN'
                Write-Verbose "Searching bcd firmware boot options for description that matches $searchString4"
                $search4 = (bcdedit /enum firmware | select-string $searchString4 -Context 3,0 -ea 0);
                Write-Verbose "Result of search: $($search4 | out-string)"
                
                # if ($null -ne $searchString4.InterfaceDescription) {
                #     $searchString4 = $searchString4.InterfaceDescription
                #     $search4 = (bcdedit /enum firmware | Where-Object { $_ -notmatch 'ipxe'} | select-string $searchString4 -Context 3,0 -ea 0);
                # }
            }
            if (($null -eq $search) -and ($null -eq $search2) -and ($null -eq $search3) -and ($null -eq $search4) -and ($null -ne $searchString5)) {
                #search for PXE string that doesn't match ipxe but does match 'PXE'
                Write-Verbose "Searching bcd firmware boot options for description that matches $searchString5"
                $search5 = (bcdedit /enum firmware | Where-Object { $_ -notmatch 'ipxe'} | select-string $searchString5 -Context 3,0 -ea 0);
                Write-Verbose "Result of search: $($search5 | out-string)"
            }
    
            if ($null -ne $search) {
                Write-verbose "Found $($search | Out-String) returning just identifier"
                $pxeID = ($search.Context.PreContext | Where-Object { $_ -match "identifier"})
                if ($null  -ne $pxeID) {
                    $pxeID = $pxeID.trimstart("identifier").trim()
                    $vbOut = $search;
                }
            } elseif($null -ne $search2) {
                Write-verbose "Found $($search2 | Out-String) returning just identifier"
                $pxeID = ($search2.Context.PreContext | Where-Object { $_ -match "identifier"})
                if ($null  -ne $pxeID) {
                    $pxeID = $pxeID.trimstart("identifier").trim()
                    $vbOut = $search2;
                }
            } elseif($null -ne $search3) {
                Write-verbose "Found $($search3 | Out-String) returning just identifier"
                $pxeID = ($search3.Context.PreContext | Where-Object { $_ -match "identifier"})
                if ($null  -ne $pxeID) {
                    $pxeID = $pxeID.trimstart("identifier").trim()
                    $vbOut = $search3;
                }
            } elseif($null -ne $search4) {
                Write-verbose "Found $($search4 | Out-String) returning just identifier"
                $pxeID = ($search4.Context.PreContext | Where-Object { $_ -match "identifier"})
                if ($null  -ne $pxeID) {
                    $pxeID = $pxeID.trimstart("identifier").trim()
                    $vbOut = $search4;
                }
            } elseif($null -ne $search5) {
                Write-verbose "Found $($search5 | Out-String) returning just identifier"
                $pxeID = ($search5.Context.PreContext | Where-Object { $_ -match "identifier"})
                if ($null  -ne $pxeID) {
                    $pxeID = $pxeID.trimstart("identifier").trim()
                    $vbOut = $search5;
                }
            } else {
                Write-Warning "no pxe boot options found in bcdedit matching $searchString!"
                $pxeID = $null;
            }
            if ($pxeID.count -gt 1) {
                if ($notBootMgr) {
                    $pxeID = $pxeID | Where-Object { $_ -notmatch "{bootmgr}"}
                } 
            } else {
                if ($pxeID -eq "{bootmgr}" -and $notBootMgr){
                    Write-Warning "Pxe id is boot manager but notBootMgr is present, returning null!"
                    $pxeID = $null
                }
            }
            "pxeID found is $pxeID full context is $($vbOut | Out-String)" | Out-Host;
            return $pxeID
        }
        
    }
    
}
