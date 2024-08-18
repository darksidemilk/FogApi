function Get-FogSetting {
    <#
    .SYNOPSIS
    Get one fog setting by name or id
    
    .DESCRIPTION
    Gets the id, name, description, and value of a given fog setting by its ID or name
    You can get all settings with Get-FogSettings
    
    .PARAMETER settingName
    The name of the setting
    
    .PARAMETER settingID
    Alternatively use the ID of the setting to get the setting directly
    
    .EXAMPLE
    Get-FogSetting -settingName FOG_QUICKREG_PENDING_MAC_FILTER

    Will return the value and info of FOG_QUICKREG_PENDING_MAC_FILTER
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        <# [ArgumentCompleter({
            param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
            $r = (Get-FogObject -type object -coreObject setting).data;
            # $r = $settings.Name.trim();

            if ($WordToComplete) {
                $r.Name.Where{ $_ -match "^$WordToComplete" }
            } else {
                $r.Name
            }
        })] #>
        $settingName,
        $settingID
    )
    
    process {
        if ((Test-FogVerAbove1dot6)) {
            if (($null -eq $settingID) -AND ($null -ne $settingName)) {
                $setting = (Get-FogSettings | Where-Object name -eq $settingName)
            } elseif ($null -ne $settingID) {
                $setting = (Get-FogObject -type object -coreObject setting -IDofObject $settingID).data
            } else {
                Write-Warning "No name or id of a setting was given!"
                $setting = $null;
            }
            return $setting;
        } else {
            Write-Warning "Getting fog config settings in the API is only available in FOG 1.6 and above!"
            return $null;
        } 
    }
    
}