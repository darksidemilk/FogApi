function Get-WinEfiMountLetter {
    <#
        .SYNOPSIS
        If the EFI partition is mounted this returns the current drive letter
        
        .DESCRIPTION
        Runs the mountvol.exe tool and parses out the string at the end of the output
        that states if and where the EFI system partition is mounted
        
    #>
        
        [CmdletBinding()]
        param (   
        )
        
        process {
            if ($IsLinux -or $IsMacOS) {
                Write-Warning "This is currently only implemented for windows"
                return $null
            } else {
                $mountVol = "C:\Windows\System32\mountvol.exe";
                #test if mountvol already has mounted a EFI partition somewhere and dismount it
                $mountVolStr = (& $mountVol)
                $currentEfiMountStr = ($mountVolStr | Select-String "EFI System Partition is mounted at");
                if ($null -ne $currentEfiMountStr) {
                    #get the substring starting at the index of the character before ':' in the drive name
                    $currentEfiMountLtr = $currentEfiMountStr.ToString().Substring(($currentEfiMountStr.ToString().indexOf(':'))-1,2); 
                    if ($null -ne $currentEfiMountLtr) {
                        return $currentEfiMountLtr;
                    }
                }
                Write-Debug "EFI partition is not currently mounted"; 
                return $null
            }
        }
        
    
    }
    