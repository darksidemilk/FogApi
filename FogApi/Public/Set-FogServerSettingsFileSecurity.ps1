function Set-FogServerSettingsFileSecurity {
    <#
    .SYNOPSIS
    Set the settings file or given file to full control for owner only, no access for anyone else
    
    .DESCRIPTION
    Uses chmod 700 for linux and mac, uses powershell acl commands for windows users to set 
    
    .PARAMETER settingsFile
    The settings file, defaults to the default path for the settings file tiy
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        $settingsFile = (Get-FogServerSettingsFile)    
    )
    
    process {
        if ($isLinux -or $IsMacOS) {
            "Setting linux permissions to only owner has rw" | Out-Host;
            chmod 600 $settingsFile
        } else {
            "Setting read/write permissions for owner only" | out-host;
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
            Set-Acl -Path $settingsFile -AclObject $acl
        }    
    }
    
}