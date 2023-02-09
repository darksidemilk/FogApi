function Set-FogServerSettings {
<#
.SYNOPSIS
Set fog server settings

.DESCRIPTION
Set the apitokens and server settings for api calls with this module
the settings are stored in a json file in the current users roaming appdata ($home/APPDATA/Roaming/FogApi)
In linux and mac machines The appdata/roaming folder will be created in the user's home folder
this is to keep it locked down and inaccessible to standard users
and keeps the settings from being overwritten when updating the module

.PARAMETER fogApiToken
fog API token is found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System

.PARAMETER fogUserToken
your fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab

.PARAMETER fogServer
your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer

.PARAMETER interactive
switch to make setting these an interactive process

.EXAMPLE
Set-FogServerSettings -fogapiToken "12345abcdefg" -fogUserToken "abcdefg12345" -fogServer "fog"

This will set the current users FogApi/settings.json file to have the given api tokens and set it to use 
"fog" as the server name for the uri in all api calls. These are of course example tokens and the actual tokens are much longer.

.EXAMPLE

#>

    [CmdletBinding(DefaultParameterSetName='default')]
    param (
        [parameter(ParameterSetName='default')]
        [string]$fogApiToken,
        [parameter(ParameterSetName='default')]
        [string]$fogUserToken,
        [parameter(ParameterSetName='default')]
        [string]$fogServer,
        [parameter(ParameterSetName='prompt')]
        [switch]$interactive
    )
    begin {
        
        $settingsFile = "$home/APPDATA/Roaming/FogApi/api-settings.json"
        # if (!(Test-path $settingsFile)) {
        #     if (!(Test-Path "$home/APPDATA")) {
        #         mkdir "$home/APPDATA"
        #     }
        #     if (!(Test-Path "$home/APPDATA/Roaming")) {
        #         mkdir "$home/APPDATA/Roaming"
        #     }
        #     if (!(Test-Path "$home/APPDATA/Roaming/FogApi")) {
        #         mkdir "$home/APPDATA/Roaming/FogApi";
        #     }
        #     Copy-Item "$script:lib\settings.json" $settingsFile -Force
        # }
        $ServerSettings = Get-FogServerSettings;
        Write-Verbose "Current/old Settings are $($ServerSettings)";
        $helpTxt = @{
            fogApiToken = "fog API token found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System";
            fogUserToken = "your fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab";
            fogServer = "your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer";
        }
        
    }
    
    process {
        if($interactive) {
            ($serverSettings.psobject.properties | Where-Object name -eq Keys).Value | ForEach-Object {
                $var = (Get-Variable -Name $_);
                if ($null -eq $var.Value -OR $var.Value -eq "") {
                        Set-Variable -name $var.Name -Value (Read-Host -Prompt "help message: $($helpTxt.($_))`nEnter the $($var.name)");        
                }
            }
        } elseif( #if all params are passed and not null create new settings object
            !([string]::IsNullOrEmpty($fogApiToken)) -AND
            !([string]::IsNullOrEmpty($fogUserToken)) -AND
            !([string]::IsNullOrEmpty($fogServer))
        ) {
            $serverSettings = @{
                fogApiToken = $fogApiToken;
                fogUserToken = $fogUserToken;
                fogServer = $fogServer;
            }
        } else {
            #check for some setting being passed but not all and set them individually
            if (!([string]::IsNullOrEmpty($fogApiToken))) {
                $ServerSettings.fogApiToken = $fogApiToken;
            }
            if (!([string]::IsNullOrEmpty($fogUserToken))) {
                $ServerSettings.fogUserToken = $fogUserToken;
            }
            if (!([string]::IsNullOrEmpty($fogServer))) {
                $ServerSettings.fogServer = $fogServer;
            }
            $serverSettings | ConvertTo-Json | Out-File -FilePath $settingsFile -Encoding oem -Force;
        }
        # If given paras are null just pulls from settings file
        # If they are not null sets the object to passed value
        
        

        Write-Verbose "making sure all settings are set";
        if ( $ServerSettings.fogApiToken -eq $helpTxt.fogApiToken -OR
            $ServerSettings.fogUserToken -eq $helpTxt.fogUserToken -OR 
            $ServerSettings.fogServer -eq $helpTxt.fogServer -or
            ([string]::IsNullOrEmpty($ServerSettings.fogApiToken)) -OR 
            ([string]::IsNullOrEmpty($ServerSettings.fogUserToken)) -OR
            ([string]::IsNullOrEmpty($ServerSettings.fogServer))
        ) {
            Write-Host -BackgroundColor Yellow -ForegroundColor Red -Object "a fog setting is either null or still set to its default help text, opening the settings file for you to set the settings"
            Write-Host -BackgroundColor Yellow -ForegroundColor Red -Object "This script will close after opening settings in notepad, please re-run command after updating settings file";
            if ($isLinux) {
                $editor = 'nano';
            }
            elseif($IsMacOS) {
                $editor = 'TextEdit';
            }
            else {
                $editor = 'notepad.exe';
            }
            Start-Process -FilePath $editor -ArgumentList "$SettingsFile" -NoNewWindow -PassThru;
            return;
        }
    }

    end {
        Write-Verbose "Writing new Settings";
        $serverSettings | ConvertTo-Json | Out-File -FilePath $settingsFile -Encoding oem -Force;
        return (Get-Content $settingsFile | ConvertFrom-Json);
    }

}
