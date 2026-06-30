function Dismount-WinEfi {
    <#
        .SYNOPSIS
        Dismounts the EFI system partition if it is currently mounted
        
        .DESCRIPTION
        Gets the efi partition mount letter and dismounts it with the mountvol tool

        .EXAMPLE
        Dismount-WinEfi

        This example will dismount the efi partition if it is currently mounted
        
    #>
        
        [CmdletBinding()]
        param ()
            
        process {
            $mountLtr=(Get-EfiMountLetter)
            if ($null -eq $mountLtr) {
                Write-Debug "EFI Partition is not mounted";
                return $null
            } else {
                $mountVol = "C:\Windows\System32\mountvol.exe";
                return Start-Process -FilePath $mountVol -Wait -NoNewWindow -ArgumentList @($mountLtr, '/D');
            }
        }    
    
    }
    