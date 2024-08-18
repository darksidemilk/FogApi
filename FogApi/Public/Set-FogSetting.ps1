function Set-FogSetting {
    <#
    .SYNOPSIS
    Set a fog setting to a given value
    
    .DESCRIPTION
    Sets the value of a setting to the given value
    No validation of the value is done, it is possible to pass an invalid value.
    Most settings are ints or strings, some have special formatting or other requirements like being a file for the banner image
    Updloading a file for a setting is not yet implemented.
    
    .PARAMETER settingName
    The name of the setting to set
    
    .PARAMETER settingID
    The id of the setting to set
    
    .PARAMETER settingObj
    Pipeline input supported.
    The object should be the result of get-fogsetting
    
    .PARAMETER value
    Tha value to apply to the setting, ensure you're sending a valid value.
    
    .EXAMPLE
    $memLimit = Get-FogSetting -settingName FOG_MEMORY_LIMIT | Set-FogSetting -value 1024

    Will get the setting object for FOG_MEMORY_LIMIT and set it to 1024 and return the new
    value in the returned object in the $memLimit variable.
    
    .EXAMPLE
    Set-FogSetting -settingName FOG_WEB_HOST -value '192.168.0.1'

    Would set the FOG_WEB_HOST to a new ip value and will return the resulting
    object of that setting

    #>
    [CmdletBinding(DefaultParameterSetName='byname')]
    param (
        [Parameter(ParameterSetName='byname')]
        [ArgumentCompleter({
            param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
            $r = Get-FogSettings;
            # $r = $settings.Name.trim();

            if ($WordToComplete) {
                $r.Name.Where{ $_ -match "^$WordToComplete" }
            } else {
                $r.Name
            }
        })]
        $settingName,
        [Parameter(ParameterSetName='byId')]
        $settingID,
        [Parameter(ParameterSetName='byObj',ValueFromPipeline=$true)]
        $settingObj,
        $value
    )
    
    
    process {
        if ($PSCmdlet.ParameterSetName -eq 'byObj') {
            if ($null -ne $_) {
                $settingObj = $_;
            }
        }
        switch ($PSCmdlet.ParameterSetName) {
            byname {
                $settingID = (Get-FogSetting -settingname $settingName).ID;
            }
            byId {
                $settingID = $settingID;
            }
            byObj {
                $settingID = $settingObj.id
            }
        }

        $jsonData = @{
            id = $settingID;
            value = $value;
        }
        return Update-FogObject -type object -coreObject setting -IDofObject $settingID -jsonData ($jsonData | ConvertTo-Json) 
    }
    
}