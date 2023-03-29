function Set-FogServerSettingsFileSecurity {
    <#
    .SYNOPSIS
    Set the settings file or given file to full control for owner only, no access for anyone else
    
    .DESCRIPTION
    Uses chmod 700 for linux and mac, uses powershell acl commands for windows users to set 
    
    .PARAMETER settingsFile
    The settings file, defaults to the default path for the settings file tiy
    
    .NOTES
    Has a try/catch on attempting to use set-acl in case permissions required aren't present on the current user in windows
    #>
    [CmdletBinding()]
    param (
        $settingsFile = (Get-FogServerSettingsFile)    
    )
    
    process {
        if ($isLinux -or $IsMacOS) {
            Write-Verbose "Setting linux permissions on api settings file so only owner has rw";
            chmod 600 $settingsFile
        } else {
            Write-Verbose "Setting read/write permissions for owner only on api settings file";
            #Get current ACL to file/folder
            $acl = Get-Acl $settingsFile
            #Disable inheritance and remove inherited permissions
            $acl.SetAccessRuleProtection($true,$false)
            #Remove all explict ACEs
            $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }
            #Create ACE for owner with full control
            $ace = New-Object System.Security.AccessControl.FileSystemAccessRule -ArgumentList $acl.Owner, "FullControl", "Allow"
            $acl.AddAccessRule($ace)
            #Save ACL to file/
            try {
                Set-Acl -Path $settingsFile -AclObject $acl
            } catch {
                icacls "$settingsFile" /reset /Q /C
                icacls "$settingsFile" /setowner $env:USERNAME /Q /C
                icacls "$settingsFile" /inheritance:r /Q /C
                icacls "$settingsFile" /grant "$env:USERNAME`:F" /Q /C
                icacls "$settingsFile" /remove 'System' /Q /C
                icacls "$settingsFile" /remove 'Administrators' /Q /C
            }
        }    
    }
    
}