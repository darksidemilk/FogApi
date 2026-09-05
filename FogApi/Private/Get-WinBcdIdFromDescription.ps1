function Get-WinBcdIdFromDescription {
<#
.SYNOPSIS
Maps a firmware boot entry description to the bcd object guid bcdedit uses for it

.DESCRIPTION
`bcdedit /set {fwbootmgr} displayorder` takes bcd object guids, while the firmware itself
names entries by number (Boot0003). The one field both sides show is the description, which
bcdedit prints verbatim as the firmware stores it - measured on a real machine, trailing
space and all.

So once the network entry has been identified honestly, by its device path, this walks
`bcdedit /enum firmware` and hands back the guid of the block whose description matches.
That means the description is used only to correlate two views of an entry already
identified, never to work out what the entry is.

Returns null when no block matches.

.PARAMETER description
The firmware's description for the entry, as read out of its Boot#### variable

.PARAMETER bcdOutput
The lines of `bcdedit /enum firmware`. Defaults to running it. Present so the parsing can be
tested against captured output.

.EXAMPLE
Get-WinBcdIdFromDescription -description 'UEFI PXEv4 (MAC:525400123456)'

Returns the {guid} bcdedit knows that entry by

.NOTES
Private helper for Get-WinBcdPxeId.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [string]$description,
        [string[]]$bcdOutput
    )

    process {
        if ($null -eq $bcdOutput) {
            if ($IsLinux -or $IsMacOS) { return $null; }
            $bcdOutput = (bcdedit /enum firmware);
        }
        if ($null -eq $bcdOutput) { return $null; }

        $wanted = $description.Trim();
        $currentId = $null;
        foreach ($line in $bcdOutput) {
            $text = "$line";
            # bcdedit prints identifier before description within each block,
            # so tracking the last identifier seen is enough.
            if ($text -match '^\s*identifier\s+(\S.*)$') {
                $currentId = $Matches[1].Trim();
                continue;
            }
            if ($text -match '^\s*description\s+(\S.*)$') {
                if (($Matches[1].Trim() -eq $wanted) -and ($null -ne $currentId)) {
                    Write-Verbose "Firmware entry '$wanted' is $currentId to bcdedit";
                    return $currentId;
                }
            }
        }
        Write-Verbose "No block in bcdedit /enum firmware has the description '$wanted'";
        return $null;
    }
}
