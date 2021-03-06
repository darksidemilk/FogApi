function Get-FogHost {
<#
    .SYNOPSIS
    Gets the object of a specific fog host
    
    .DESCRIPTION
    Searches a new or existing object of hosts for a specific host (or hosts) with search options of uuid, hostname, or mac address
    if no search terms are specified then it gets the search terms from your host that is making the request and tries to find your
    computer in fog
    
    .PARAMETER uuid
    the uuid of the host
    
    .PARAMETER hostName
    the hostname of the host
    
    .PARAMETER macAddr
    a mac address linked to the host
    
    .PARAMETER hosts
    defaults to calling Get-FogHosts but if you already have that in an object you can pass it here to speed up processing
    
    .EXAMPLE
    Get-FogHost -hostName MewoMachine
    
    This would return the fog details of a host named MeowMachine in your fog instance

    .EXAMPLE
    Get-FogHost

    If you specify no param it will return your current host from fog

#>
    
    [CmdletBinding()]
    param (
        [string]$uuid,
        [string]$hostName,
        [string]$macAddr,
        [string]$hostID,
        $hosts = (Get-FogHosts)
    )

    begin {
        [bool]$found = $false;
        Write-Verbose 'Checking for passed variables'
        if (!$uuid -and !$hostName -and !$macAddr -and !$hostID) {
            Write-Verbose 'no params given, getting current computer variables';
            try {
                $compSys = (Get-WmiObject Win32_ComputerSystemProduct);
            } catch {
                $compSys = Get-CimInstance -ClassName win32_computersystemproduct
            }
            if ($compSys.UUID -notmatch "12345678-9012-3456-7890-abcdefabcdef" ) {
                $uuid = $compSys.UUID;
            } else {
                $uuid = ($compSys.Qualifiers | Where-Object Name -match 'UUID' | Select-Object -ExpandProperty Value);
            }
            $macAddr = ((Get-NetAdapter | Select-Object MacAddress)[0].MacAddress).Replace('-',':');
            $hostName = $(hostname);
        }
        Write-Verbose 'getting all hosts to search...';
        Write-Verbose "search terms: uuid is $uuid, macAddr is $macAddr, hostname is $hostName";
    }

    process {
        Write-Verbose 'finding host in hosts';
        [bool]$found = $false;
        if ($hostID) {
            $hostObj = $hosts | Where-Object id -eq $hostID;
            if ($null -ne $hostObj) {
                $found = $true;
            }
        } else {
            $hostObj = $hosts | Where-Object {
                ($uuid -ne "" -AND $_.inventory.sysuuid -eq $uuid) -OR `
                ($hostName -ne "" -AND $_.name -eq $hostName) -OR `
                ($macAddr -ne "" -AND $_.macs -contains $macAddr);
                if  ($uuid -ne "" -AND $_.inventory.sysuuid -eq $uuid) {
                    Write-Verbose "$($_.inventory.sysuuid) matches the uuid $uuid`! host found";
                    $found = $true;
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
                "Multiple hosts found! Review hosts in return object and select just one if needed" | Out-Host;
            }

            return $hostObj;
        }
        return $found; #return false if host not found
    }

}
