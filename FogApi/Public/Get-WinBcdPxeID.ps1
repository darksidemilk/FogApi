function Get-WinBcdPxeId {
    <#
    .SYNOPSIS
    Searches bcd firmware options for a given or model specific search string and returns the boot device guid 
    
    .DESCRIPTION
    Searches bcd firmware options for a given or model specific search string and returns the boot device guid 
    The id can be used with `bcdedit /set "{fwbootmgr}" displayorder $pxeID /addfirst` to be set as the first boot option in the computer's bios boot order
    
    .PARAMETER searchString
    Optionatlly specify a search string, can be pxe related or try to find a different id from `bcdedit /enum firmware`

    .PARAMETER notBootMgr
    switch param to not return the main bootmgr entry if it is returned

    .EXAMPLE
    Get-BcdPxeBootID

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
        } else {
            if (!(Test-String $searchString)) {
                $searchString = "IPV4"
                $searchString2 = "Network"
                $searchString3 = "LAN"
                $searchString4 = (Get-NetAdapter -ea 0 | Where-Object status -eq up | Where-Object name -match 'Ethernet' | Select-Object -First 1)
                $searchString5 = "PXE"
            }
            Write-Verbose "Searching bcd firmware boot options for description that matches $searchString"
            $search = (bcdedit /enum firmware | select-string $searchString -Context 3,0 -ea 0);
            if ($null -ne $searchString2) {
                #search for PXE string that doesn't match ipxe that might match 'Network' (or 'EFI Network' on a surface go 2)
                $search2 = (bcdedit /enum firmware | Where-Object { $_ -notmatch 'ipxe'} | select-string $searchString2 -Context 3,0 -ea 0);
            }
            if (($null -eq $search2) -and ($null -ne $searchString3)) {
                #search for PXE string that doesn't match ipxe but does match 'LAN'
                $search3 = (bcdedit /enum firmware | Where-Object { $_ -notmatch 'ipxe'} | select-string $searchString3 -Context 3,0 -ea 0);
            }
            if (($null -eq $search3) -and ($null -ne $searchString4)) {
                #search for PXE string that doesn't match ipxe but does match the interface description of the first ethernet adapter that is currently up
                if ($null -ne $searchString4.InterfaceDescription) {
                    $searchString4 = $searchString4.InterfaceDescription
                    $search4 = (bcdedit /enum firmware | Where-Object { $_ -notmatch 'ipxe'} | select-string $searchString4 -Context 3,0 -ea 0);
                }
            }
            if (($null -eq $search4) -and ($null -ne $searchString5)) {
                #search for PXE string that doesn't match ipxe but does match 'PXE'
                $search5 = (bcdedit /enum firmware | Where-Object { $_ -notmatch 'ipxe'} | select-string $searchString5 -Context 3,0 -ea 0);
            }
    
            if ($null -ne $search) {
                Write-verbose "Found $($search | Out-String) returning just identifier"
                $pxeID = ($search.Context.PreContext | Where-Object { $_ -match "identifier"})
                if ($null  -ne $pxeID) {
                    $pxeID = $pxeID.trimstart("identifier").trim()
                }
            } elseif($null -ne $search2) {
                Write-verbose "Found $($search2 | Out-String) returning just identifier"
                $pxeID = ($search2.Context.PreContext | Where-Object { $_ -match "identifier"})
                if ($null  -ne $pxeID) {
                    $pxeID = $pxeID.trimstart("identifier").trim()
                }
            } elseif($null -ne $search3) {
                Write-verbose "Found $($search3 | Out-String) returning just identifier"
                $pxeID = ($search3.Context.PreContext | Where-Object { $_ -match "identifier"})
                if ($null  -ne $pxeID) {
                    $pxeID = $pxeID.trimstart("identifier").trim()
                }
            } elseif($null -ne $search4) {
                Write-verbose "Found $($search4 | Out-String) returning just identifier"
                $pxeID = ($search4.Context.PreContext | Where-Object { $_ -match "identifier"})
                if ($null  -ne $pxeID) {
                    $pxeID = $pxeID.trimstart("identifier").trim()
                }
            } elseif($null -ne $search5) {
                Write-verbose "Found $($search5 | Out-String) returning just identifier"
                $pxeID = ($search5.Context.PreContext | Where-Object { $_ -match "identifier"})
                if ($null  -ne $pxeID) {
                    $pxeID = $pxeID.trimstart("identifier").trim()
                }
            } else {
                Write-Warning "no pxe boot options found in bcdedit matching $searchString!"
                $pxeID = $null;
            }
            if ($pxeID.count -gt 1) {
                if ($notBootMgr) {
                    $pxeID = $pxeID | Where-Object { $_ -notmatch "{bootmgr}"}
                } else {
                    Write-Warning "Multiple entries returned, returning only first entry`n$($pxeID | Out-String)"
                    $pxeID = $pxeID[0];
                }
            } else {
                if ($pxeID -eq "{bootmgr}" -and $notBootMgr){
                    Write-Warning "Pxe id is boot manager but notBootMgr is present, returning null!"
                    $pxeID = $null
                }
            }
            return $pxeID
        }
        
    }
    
}
