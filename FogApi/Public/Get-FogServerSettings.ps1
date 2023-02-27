function Get-FogServerSettings {
<#
.SYNOPSIS
Gets the server settings set for this module

.DESCRIPTION
Gets the current settings for use in api calls
If no settings exists creates and returns the default settings which explain where to get each setting.
For getting the default file path for the server settings file, it uses get-fogserversettingsfile that will get the path based on the os and user
If the path doesn't exist it will be created and the security settings will be set by Set-FogServerSettingsFileSecurity

.EXAMPLE
Get-FogServerSettings

Converts the json settings file to a powershell object
and returns the api key and server name values

#>

    [CmdletBinding()]
    param ()

    process {
        Write-Verbose "Pulling settings from settings file"
        #since we updated the fog settings file path for linux and mac systems, make it auto migrate if the old settings exists
        $settingsFile = Get-FogServerSettingsFile;
        
        $move = $false;
        if ($isLinux -or $IsMacOS) {
            $oldsettingsFile = "$home/APPDATA/Roaming/FogApi/api-settings.json"
            if (Test-Path $oldsettingsFile) {
                $move = $true;
            }
        }

        if (!(Test-path $settingsFile)) {
            Write-Warning "Api Settings file not yet created, creating default version now!"
            try {
                #create just the parent path with built-in mkdir
                if (!(test-path (split-path $settingsFile -Parent))) {
                    mkdir (split-path $settingsFile -Parent)
                }
            } catch {
                #error creating parent path(s), looping through full path and using pwsh methods to create each part of the full path
                set-location "/"
                (split-path $settingsFile -Parent) -split "/" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object {
                    if (!(Test-Path $_)) {
                        new-item -path $_ -ItemType Directory -ea 0
                    }
                    Set-Location $_;
                }
            }
            if ($move) {
                Write-Host -BackgroundColor Yellow -ForegroundColor White -Object "The settings file path has changed from $oldSettingsFile to $SettingsFile. The permissions are also being updated to be more secure (rw for owner only)"
                $oldParentPath = Split-Path $oldsettingsFile -Parent;
                try {
                    Move-Item -path $oldsettingsFile -Destination $settingsFile -ea stop
                } catch {
                    Copy-Item -path $oldsettingsFile -Destination $settingsFile -ea 0 -force;
                    Write-Warning "there was an error moving the file, it was copied instead, please remove the $oldParentPath manually"
                }
                if ( ((Get-ChildItem $oldParentPath -force).count) -eq 0) {
                    Write-Host -BackgroundColor Yellow -ForegroundColor White -Object "The old settings parent directory is empty"
                    Remove-Item $oldParentPath -Force -Recurse;
                } else {
                    Write-Warning "The old settings path was not empty, please remove the $oldParentPath manually to stop these warnings"
                }
                Set-FogServerSettingsFileSecurity -settingsFile $settingsFile;
            } else {
                Copy-Item -path "$script:lib\settings.json" -Destination $settingsFile -Force
                Set-FogServerSettingsFileSecurity -settingsFile $settingsFile;
            }
        }       
        $serverSettings = (Get-Content $settingsFile | ConvertFrom-Json);
        return $serverSettings;
    }

}
