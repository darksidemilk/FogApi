function New-FogHost {
    <#
    .SYNOPSIS
    Creates a new host in fog
    
    .DESCRIPTION
    Has 2 parameter sets,
    a default set that lets you create a simple host with a name, mac addr or list of macs,  and either specified fog service/client modules or the ones you have configured as default on your fog server. 
    And a custom mode that lets you pass a custom host object that you'll need to validate yourself, but you can then add snapins, groups, etc in the host creation object. This is an advanced method and no validation is currently provided
    When using the default set of params some validation is performed, the name is checked for whitespace, if there is whitespace it is replaced with a '-' unless it's at the end of the string
    It will also check if any hosts already exist with the given name or the given mac addresses, if one does exist the existing host is returned.
    If a new host is created, that host object is returned
    
    .PARAMETER name
    The hostname of the new fog host, should not have spaces or special characters other than '-' or '_'
    Should follow general hostname rules. Only whitespace is currently checked. If you input an invalid hostname it may create the host but you won't be able to view the host in fog
    
    .PARAMETER macs
    A single or list of mac addresses for the host. The first mac in the list will be the primary.
    Mac's should be in the format "00:01:23:45:67:89" additional macs can be added as a comma separated list to create a string array
    
    .PARAMETER modules
    The ids of the modules to enable on the host. 
    Defaults to getting the modules you have set to be enabled on the fog server
    You can view your existing modules and create a custom list by utilizing Get-FogModules
    
    .PARAMETER customHost
    Optionally specify a full host object to create a host object with additional params such as snapinIds and groupids,
    this parameter has less testing done on it but is provided for flexibility until more default parameters are added.
    A customHost object should at least have the properties name and macs and can have additional ones as well.
    It can be created like this 
    $customHost = @{
        name = "name";
        macs = "00:01:23:45:67:89";
        modules = ((Get-FogModules | Where-Object isDefault -eq '1') | Select-Object -ExpandProperty id);
    }
    Refer to the fog api documentaiton and the forums for information on additional properties to add
    
    .EXAMPLE
    New-FogHost -name "test-host" -macs "01:23:45:67:89:00"

    Will create a new host in fog with the name "test-host"

    #>
    [CmdletBinding(DefaultParameterSetName='default')]
    [Alias('Add-FogHost')]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='default')]
        [string]$name,
        [Parameter(Mandatory=$true,ParameterSetName='default')]
        [string[]]$macs,
        [Parameter(ParameterSetName='default')]
        [string[]]$modules = ((Get-FogModules | Where-Object isDefault -eq '1') | Select-Object -ExpandProperty id),
        [Parameter(Mandatory=$true,ParameterSetName='custom')]
        [object]$customHost
    )
    
    begin {
        if ($PSCmdlet.ParameterSetName -eq 'default') {

            if ($name -match " ") {
                Write-Warning "name $name includes whitespace, replacing whitespace with - if not at end of string";
                $name = $name.TrimEnd();
                $name = $name.Replace(" ","-");
                "new name is $name" | Out-Host;
            }
            $hostObject = @{
                name = $name;
                macs = $macs;
                modules = $modules;
            }
        } else {
            $hostObject = $customHost;
            "Custom host is specified, no validation being performed, object properties are $($hostObject | Out-String)"
        }
        $hostJson = $hostObject | ConvertTo-Json;
        
    }
    
    process {
        if ($PSCmdlet.ParameterSetName -eq 'default') {
            try {
                Write-Verbose "Checking for existing name"
                $hostNameCheck = Get-FogHost -hostName $name;
                if ($hostNameCheck) {
                    Write-Warning "host with name $name already exists, returning existing host object";
                    return $hostNameCheck;                     
                }
                $hostMacCheck = New-Object System.Collections.Generic.list[object];
                $macs | ForEach-Object {
                    "Checking for existings host with mac $($_)" | Out-Host;
                    $hostMacCheckItem = (Get-FogHost -macAddr $_);
                    if ($hostMacCheckItem) {
                        Write-Warning "mac address $($_) already exists on host $($hostMacCheckItem.name)";
                        $hostMacCheck.add(($hostMacCheckItem));
                    }
                }
                if ($hostMacCheck.count -gt 0) {
                    Write-Warning "some macs already exist on hosts, returning list of matching host objects";
                    return $hostMacCheck;
                }

            } catch {
                Write-Warning "Error during input validation, attempting to create new host"
            }
        }
        "Creating new Host $hostObject" | Out-Host;
        
        $newHost = New-FogObject -type object -coreObject host -jsonData $hostJson
    }
    
    end {
        if ($null -ne $newHost) {
            return $newHost;
        }
    }
}