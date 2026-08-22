function Get-FogHost {
<#
    .SYNOPSIS
    Gets the object of a specific fog host
    
    .DESCRIPTION
    Searches a new or existing object of hosts for a specific host (or hosts) with search options of uuid, hostname, or mac address
    if no search terms are specified then it gets the search terms from your host that is making the request and tries to find your
    computer in fog. IF you specify the id of the host, then only that host is queried for in the api, otherwise it gets all hosts and searches
    that object with the given parameters.
    
    .PARAMETER uuid
    the uuid of the host
    
    .PARAMETER hostName
    the hostname of the host, if your FOG version is 1.6 or above you can use tab complete for hostnames
    
    .PARAMETER macAddr
    a mac address linked to the host
    
    .PARAMETER hosts
    defaults to calling Get-FogHosts but if you already have that in an object you can pass it here to speed up processing
    
    .EXAMPLE
    Get-FogHost -hostName MeowMachine

    This would return the fog details of a host named MeowMachine in your fog instance
    If using pwsh 7+ and your FOG service is 1.6 or above, you can tab complete to search for existing hosts by name

    Expected output:
    { "name": "MeowMachine", "id": 42 }

    .EXAMPLE
    Get-FogHost

    If you specify no param it will return your current host from fog

    .EXAMPLE
    Get-FogHost -hostID 1234

    Will get the host of id 1234 directly, this is the fastest way to call the function

    .EXAMPLE
    Get-FogHost -serialNumber 12345678

    Will find the given serial number in fog server inventory and then find the host of the hostID that inventory belongs to

#>
    
    [CmdletBinding(DefaultParameterSetName='searchTerm')]
    param (
        [parameter(ParameterSetName='searchTerm')]
        [string]$uuid,
        [parameter(ParameterSetName='searchTerm')]
        [ArgumentCompleter({
            param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
            if(Test-FogVerAbove1dot6) {
                $r = Get-FogHosts;

                if ($WordToComplete) {
                    $r.Name.Where{ $_ -match "^$WordToComplete" }
                }
                else {
                    $r.Name
                }
            }
        })]  
        [string]$hostName,
        [parameter(ParameterSetName='searchTerm')]
        [string]$macAddr,
        [parameter(ParameterSetName='byID',Mandatory=$true)]
        [string]$hostID,
        [parameter(ParameterSetName='serialNumber',Mandatory=$true)]
        [string]$serialNumber
    )

    begin {
        [bool]$found = $false;
        Write-Verbose 'Checking for passed variables'
        if ($serialNumber) {
            $inventorys = (Get-FogObject -type object -coreObject inventory).data
            $hostID = $inventorys | Where-Object { $_.sysserial -eq $serialNumber -OR $_.mbserial -eq $serialNumber -OR $_.caseserial -eq $serialNumber } | Select-Object -ExpandProperty HostID #find the inventory where the serial number matches one of the serial numbers in a hosts inventory and select the host id from that
        } elseif (!$uuid -and !$hostName -and !$macAddr -and !$hostID) {
            Write-Verbose 'no params given, getting current computer variables';
            $identity = Get-FogLocalIdentity;
            $uuid = $identity.uuid;
            $macAddr = $identity.macAddress;
            $hostName = $identity.hostName;
        } else {
            if ($hostID) {
                Write-Verbose "getting host from ID $hostID directly..."
            }
        }
        Write-Verbose 'getting all hosts to search...';
        Write-Verbose "search terms: uuid is $uuid, macAddr is $macAddr, hostname is $hostName";
    }

    process {
        Write-Verbose 'finding host in hosts';
        [bool]$found = $false;
        if ($hostID) {
            $hostObj = Get-FogObject -type object -coreObject host -IDofObject "$hostID";
            if ($null -ne $hostObj) {
                $found = $true;
            }
        } else {
            $hosts = (Get-FogHosts)
            #these guards used to be '$uuid -ne ""', but $null -ne "" is true, so a null
            #search term degenerated into 'sysuuid -eq $null' and matched every host that
            #has no inventory uuid. Callers feed this straight into Update-FogObject, so a
            #wrong match here writes to the wrong host record on the server
            [bool]$haveUuid = -not [string]::IsNullOrWhiteSpace($uuid);
            [bool]$haveName = -not [string]::IsNullOrWhiteSpace($hostName);
            [bool]$haveMac  = -not [string]::IsNullOrWhiteSpace($macAddr);
            if (!$haveUuid -and !$haveName -and !$haveMac) {
                #no 'return' here - returning from process() does not skip end(), so it would
                #emit a value and then let end() emit $found as well
                Write-Error "No usable search terms for this host. The local machine identity could not be determined, which is expected under pwsh on linux and mac. Pass -hostName, -macAddr, -uuid, -hostID or -serialNumber explicitly.";
                $hostObj = $null;
            } else {
                $hostObj = $hosts | Where-Object {
                    ($haveUuid -AND $_.inventory.sysuuid -eq $uuid) -OR `
                    ($haveName -AND $_.name -eq $hostName) -OR `
                    ($haveMac -AND $_.macs -contains $macAddr);
                    if  ($haveUuid -AND $_.inventory.sysuuid -eq $uuid) {
                        $found = $true;
                        Write-Verbose "$($_.inventory.sysuuid) matches the uuid $uuid`! host found is $found";
                    }
                    if ($haveMac -AND $_.macs -contains $macAddr) {
                        Write-Verbose "$($_.macs) matches the macaddress $macAddr`! host found";
                        $found = $true;
                    }
                    if  ($haveName -AND $_.name -eq $hostName) {
                        Write-Verbose "$($_.name) matches the hostname $hostName`! host found";
                        $found = $true;
                    }
                }
            }
        }
    }

    end {
        if ($found){
            if ($hostObj.count -gt 1) {
                if ($hostName) { 
                    $hostObjByName = $hostObj | Where-Object name -eq $hostName;
                    if ($null -ne $hostObjByName) {
                        $hostObj = $hostObjByName
                    } else {
                        "Multiple hosts found and none of them match given hostname! Review hosts in return object and select just one if needed" | Out-Host;
                    }
                } else {
                    "Multiple hosts found! Review hosts in return object and select just one if needed" | Out-Host;
                }
            }
            if ($null -eq ($hostObj | Get-Member -Name ADOU)) {
                Write-Verbose "Host is $($hostObj | out-string) which is missing adou, reobtaining with id"
                $hostID = $hostObj.id;
                $hostObj = (Get-Fogobject -type object -coreObject host -IDofObject "$hostID");
            }
            # Stamp the ETS type name so Register-FogTypeData's display set and
            # methods apply. Additive on purpose: nothing is reshaped, converted or
            # dropped, so every field the server sent stays where callers expect it.
            # That matters more than it sounds -- a stock 1.6 host response carries
            # 39 fields and components.schemas.Host declares 30, because the schema
            # reflects the model's own columns while the route returns the entity
            # joined to its relations. Two of the nine undeclared ones (macs,
            # inventory) are read by this very function.
            foreach ($h in @($hostObj)) {
                if ($null -ne $h -and $h.PSObject.TypeNames[0] -ne 'FogApi.Host') {
                    $h.PSObject.TypeNames.Insert(0, 'FogApi.Host');
                }
            }
            return $hostObj;
        }
        return $found; #return false if host not found
    }

}
