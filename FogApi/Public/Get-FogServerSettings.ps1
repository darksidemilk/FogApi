function Get-FogServerSettings {
<#
.SYNOPSIS
Gets the server settings set for this module

.DESCRIPTION
Gets the current settings for use in api calls
If no settings exists creates and returns the default settings

.EXAMPLE
Get-FogServerSettings

Converts the json settings file to a powershell object
and returns the api key and server name values

#>

    [CmdletBinding()]
    param ()

    begin {
        Write-Verbose "Pulling settings from settings file"
        $settingsFile = "$home/APPDATA/Roaming/FogApi/api-settings.json"
        if (!(Test-path $settingsFile)) {
            Write-Warning "Api Settings file not yet created, creating default version now!"
            if (!(Test-Path "$home/APPDATA")) {
                mkdir "$home/APPDATA"
            }
            if (!(Test-Path "$home/APPDATA/Roaming")) {
                mkdir "$home/APPDATA/Roaming"
            }
            if (!(Test-Path "$home/APPDATA/Roaming/FogApi")) {
                mkdir "$home/APPDATA/Roaming/FogApi";
            }
            Copy-Item -path "$script:lib\settings.json" -Destination $settingsFile -Force
        }       
    }

    process {
        $serverSettings = (Get-Content $settingsFile | ConvertFrom-Json);
    }

    end {
        return $serverSettings;
    }

}
