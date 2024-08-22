function Mount-WinEfi {
    <#
        .SYNOPSIS
        Mounts the EFI system partition to a specified mount letter
        
        .DESCRIPTION
        Uses the mountvol tool to mount the system partition
        defaults to using A:\ but other drive letters can be specified.
        If it is already mounted on the specified drive it will return null
        if it is already mounted on a different drive, it will dismount it and remount on the specified letter
        Use get-efimountletter to get where it is currently mounted
        
        .PARAMETER mountLtr
        The mount letter to use in A: format for mounting the EFI system partition
    
    #>
        
        [CmdletBinding()]
        param (
            $mountLtr='A:'
        )
        
        process {
            if ($IsLinux -or $IsMacOS) {
                Write-Warning "This is currently only implemented for windows"
                return $null;
            } else {
                $mountVol = "C:\Windows\System32\mountvol.exe";
                #test if mountvol already has mounted a EFI partition somewhere and dismount it
                $currentEfiMountLtr = Get-EfiMountLetter
                if ($null -ne $currentEfiMountLtr) {
                    if ($mountLtr -match $currentEfiMountLtr) {
                        Write-Debug "EFI partition already mounted at $currentEfiMountLtr, nothing to do";
                        return $null
                    } else {
                        Write-Debug "EFI partition already mounted at $currentEfiMountLtr, Dismounting and remounting at specifed mount letter of $mountltr";
                        Dismount-WinEFI;
                    }
                }
                if ((get-psdrive | Where-Object Root -match $mountltr)) { #test is mountltr is already in use and remove if it is
                    Write-Debug "Dismounting non EFI drive already mounted at $mountltr"
                    Remove-PSDrive $mountLtr;
                }
                return Start-Process -FilePath $mountVol -Wait -NoNewWindow -ArgumentList @($mountLtr, '/S'); 
            }
        }
        
    
    }
    