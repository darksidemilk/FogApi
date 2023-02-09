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
    the hostname of the host
    
    .PARAMETER macAddr
    a mac address linked to the host
    
    .PARAMETER hosts
    defaults to calling Get-FogHosts but if you already have that in an object you can pass it here to speed up processing
    
    .EXAMPLE
    Get-FogHost -hostName MeowMachine
    
    This would return the fog details of a host named MeowMachine in your fog instance

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
            try {
                $compSys = Get-CimInstance -ClassName win32_computersystemproduct
            } catch {
                $compSys = (Get-WmiObject Win32_ComputerSystemProduct);
            }
            if ($compSys.UUID -notmatch "12345678-9012-3456-7890-abcdefabcdef" ) {
                $uuid = $compSys.UUID;
            } else {
                $uuid = ($compSys.Qualifiers | Where-Object Name -match 'UUID' | Select-Object -ExpandProperty Value);
            }
            # $macAddr = ((Get-NetAdapter | Select-Object MacAddress)[0].MacAddress).Replace('-',':');
            $make = Get-CimInstance -classname win32_computersystem | Select-Object -ExpandProperty manufacturer
            if (($Make) -notmatch "vmware" ) { 
                $macAddr = (
                    Get-NetAdapter | Where-Object { 
                        $_.Status -eq 'up' -And $_.Name -notmatch 'VMware'
                    } | Select-Object -first 1 | Select-Object -expand MacAddress
                ).Replace("-",":");
            } else {
                $macAddr = (
                    Get-NetAdapter | Where-Object { 
                        $_.Status -eq 'up'
                    } | Select-Object -first 1 | Select-Object -expand MacAddress
                ).Replace("-",":");
            }
            $hostName = $(hostname);
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
            $hostObj = $hosts | Where-Object {
                ($uuid -ne "" -AND $_.inventory.sysuuid -eq $uuid) -OR `
                ($hostName -ne "" -AND $_.name -eq $hostName) -OR `
                ($macAddr -ne "" -AND $_.macs -contains $macAddr);
                if  ($uuid -ne "" -AND $_.inventory.sysuuid -eq $uuid) {
                    $found = $true;
                    Write-Verbose "$($_.inventory.sysuuid) matches the uuid $uuid`! host found is $found";
                }
                if ($macAddr -ne "" -AND $_.macs -contains $macAddr) {
                    Write-Verbose "$($_.macs) matches the macaddress $macAddr`! host found";
                    $found = $true;
                }
                if  ($hostName -ne "" -AND $_.name -eq $hostName) {
                    Write-Verbose "$($_.name) matches the hostname $hostName`! host found";
                    $found = $true;
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

            return $hostObj;
        }
        return $found; #return false if host not found
    }

}
