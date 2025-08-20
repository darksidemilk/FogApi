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
You can enforce the use of http or https in api calls by specifying the servername as https://fogserver or http://fogserver,
you can also use Enable-FogApiHTTPS or Disable-FogApiHTTPS later to enable or disable https in the api calls.
If you specify the hostname or ip without http or https, it will default to prepending http:// for you.

.PARAMETER interactive
switch to make setting these an interactive process, if you set no values this is the default
Warning, this can have issues in linux, especially when working in a remote shell, the paste into read-host can behave odd.

.EXAMPLE
Set-FogServerSettings -fogapiToken "12345abcdefg" -fogUserToken "abcdefg12345" -fogServer "fog"

This will set the current users FogApi/settings.json file to have the given api tokens and set it to use 
"fog" as the server name for the uri in all api calls. These are of course example tokens and the actual tokens are much longer.

.EXAMPLE

#>

    [CmdletBinding(DefaultParameterSetName='prompt')]
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

    process {
        $settingsFile = Get-FogServerSettingsFile;
        $ServerSettings = Get-FogServerSettings;
        Write-Verbose "Current/old Settings are $($ServerSettings)";
        $initialSettings = Get-content -raw "$script:lib\settings.json" | ConvertFrom-Json
        $helpTxt = @{
            fogApiToken = $initialSettings.fogApiToken; # "fog API token found at http://fog-server/fog/management/index.php?node=about&sub=settings under API System";
            fogUserToken = $initialSettings.fogUserToken; # "your fog user api token found in the user settings http://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab";
            fogServer = $initialSettings.fogServer; # "your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer, to enforce http/https input this as https://fogserver or http://fogserver, you can also use Enable-FogApiHTTPS later";
        }
        if (Test-StringNotNullOrEmpty -str $fogServer) {
            if (($fogServer -notlike "http://*") -and ($fogServer -notlike "https://*")) {
                Write-Warning "raw server name $fogServer does not start with http:// or https://, prepending http:// to the server name, use enable-fogapihttps to enforce https in api calls later if desired";
                $fogServer = "http://$fogServer";
            }
        }
        if($interactive -or $PSCmdlet.ParameterSetName -eq 'prompt') {
            if ($IsLinux) {
                Write-Warning "If you have issues with pasting your apikeys into these prompts (issue with read-host in some linux instances of pwsh), try again without -interactive and paste into each param. i.e. `Set-FogServerSettings -fogapiToken '12345abcdefg' -fogUserToken 'abcdefg12345' -fogServer 'fog'"
            }
            ($serverSettings.psobject.properties).Name | ForEach-Object {
                $var = (Get-Variable -Name $_);
                if ($null -eq $var.Value -OR $var.Value -eq "") {
                    Set-Variable -name $var.Name -Value (Read-Host -Prompt "help message: $($helpTxt.($_))`nEnter the $($var.name)");
                }    
            }
            $serverSettings = @{
                fogApiToken = $fogApiToken;
                fogUserToken = $fogUserToken;
                fogServer = $fogServer;
            }
            $serverSettings | ConvertTo-Json | Out-File -FilePath $settingsFile -Encoding oem -Force;
        } elseif( #if all params are passed and not null create new settings object
            (Test-StringNotNullOrEmpty -str $fogApiToken) -AND
            (Test-StringNotNullOrEmpty -str $fogUserToken) -AND
            (Test-StringNotNullOrEmpty -str $fogServer)
        ) {
            Write-Verbose "All parameters present, creating new settings object";
            $serverSettings = @{
                fogApiToken = $fogApiToken;
                fogUserToken = $fogUserToken;
                fogServer = $fogServer;
            }
        } else {
            #check for some setting being passed but not all and set them individually
            if ((Test-StringNotNullOrEmpty -str $fogApiToken)) {
                $ServerSettings.fogApiToken = $fogApiToken;
            } else {
                Write-Verbose "fogapitoken not given, keeping old value of $($ServerSettings.fogApiToken)";
            }
            if ((Test-StringNotNullOrEmpty -str $fogUserToken)) {
                $ServerSettings.fogUserToken = $fogUserToken;
            } else {
                Write-Verbose "fogusertoken not given, keeping old value of $($ServerSettings.fogUserToken)";
            }
            if ((Test-StringNotNullOrEmpty -str $fogServer)) {
                $ServerSettings.fogServer = $fogServer;
            } else {
                Write-Verbose "fogserver not given, keeping old value of $($ServerSettings.fogServer)";
            }
            # $serverSettings | ConvertTo-Json | Out-File -FilePath $settingsFile -Encoding oem -Force;
        }
        # If given params are null just pulls from settings file
        # If they are not null sets the object to passed value
        
        

        Write-Verbose "making sure all settings are set";
        if ( ($ServerSettings.fogApiToken -eq $helpTxt.fogApiToken -or $ServerSettings.fogApiToken -match " ") -OR
            ($ServerSettings.fogUserToken -eq $helpTxt.fogUserToken -or $ServerSettings.fogUserToken -match " ") -OR
            ($ServerSettings.fogServer -eq $helpTxt.fogServer -or $ServerSettings.fogServer -match " ") -or
            !(Test-StringNotNullOrEmpty -str $ServerSettings.fogApiToken) -OR
            !(Test-StringNotNullOrEmpty -str $ServerSettings.fogUserToken) -OR
            !(Test-StringNotNullOrEmpty -str $ServerSettings.fogServer)
        ) {
            Write-Host -BackgroundColor Yellow -ForegroundColor Red -Object "a fog setting is either null, still set to its default help text, or contains whitespace, opening the settings file for you to set the settings"
            Write-Host -BackgroundColor Yellow -ForegroundColor Red -Object "This script will close after opening settings in notepad, please re-run command after updating settings file";
            if ($isLinux) {
                if (Get-Command nano) {
                    $editor = 'nano';
                } else {
                    $editor = 'vi';
                }
            }
            elseif($IsMacOS) {
                $editor = 'TextEdit';
            }
            else {
                if ((Get-Command 'code.cmd' -ea 0)) {
                    $editor = 'code.cmd';
                } else {
                    $editor = 'notepad.exe';
                }
            }
            Start-Process -FilePath $editor -ArgumentList "$SettingsFile" -NoNewWindow -PassThru;
            return;
        }
        Write-Verbose "Writing new Settings";
        $serverSettings | ConvertTo-Json | Out-File -FilePath $settingsFile -Encoding oem -Force;
        Write-Verbose "ensuring security is set"
        $sec = Set-FogServerSettingsFileSecurity $settingsFile;
        Write-Verbose "Security settings applied:$($sec | Out-String)"
        return (Get-Content $settingsFile | ConvertFrom-Json);
    }

}
