function Get-FogInventory {
<#
    .SYNOPSIS
    Gets a local computer's inventory with wmi and returns 
    a json object that can be used to set fog inventory

    .DESCRIPTION
    Uses various wmi classes to get every possible inventory item to set in fog

    .PARAMETER hostObj
    the host to get the model of the inventory object from
    This is used for the inventory structure of the object
    It defaults to the current host

    .PARAMETER fromFog
    Switch param to simply return the currently set inventory of the fog host

    .EXAMPLE
    $json = Get-FogInventory; Set-FogInventory -jsonData $json

    Gets the inventory of the currenthost using cim and formats in the proper json
    then sets the inventory for that host in fog.

    .EXAMPLE
    Get-FogInventory -fromFog

    Will return the inventory currently set on the fog host of the current computer
    This will happen automatically if you run it from powershell core in linux as getting
    the inventory of the linux machine isn't yet implemented

#>

    [CmdletBinding()]
    [Alias('Get-FogHostInventory','Get-WinInventoryForFog')]
    param (
        [Parameter(ValueFromPipeline=$true)]
        $hostObj = (Get-FogHost),
        [switch]$fromFog
    )

    process {
        if ($null -ne $_) {
            $hostObj = $_;
        }
        if ($IsLinux -OR $fromFog) {
            if ($IsLinux) {
                "Not yet implemented for getting the host inventory from linux inline, returning the hosts currently set inventory object" | out-host;
            }
            if ($null -eq $hostObj.inventory) {
                return (Get-FogHost -hostID $hostObj.ID).inventory
            } else {
                return $hostObj.inventory;
            }
        }
        else {
            $comp = Get-CimInstance -ClassName Win32_ComputerSystem;
            $compSys = Get-CimInstance -ClassName Win32_ComputerSystemProduct;
            $cpu = Get-CimInstance -ClassName Win32_processor;
            $bios = Get-CimInstance -ClassName Win32_Bios;
            $hdd = Get-CimInstance -ClassName Win32_DiskDrive | Where-Object DeviceID -match '0'; #get just drive 0 in case of multiple drives
            $baseBoard = Get-CimInstance -ClassName Win32_BaseBoard;
            $case = Get-CimInstance -ClassName Win32_SystemEnclosure;
            $info = Get-ComputerInfo;
            $hostObj.inventory.hostID        = $hostObj.id;
            # $hostObj.inventory.primaryUser   =
            # $hostObj.inventory.other1        =
            # $hostObj.inventory.other2        =
            $hostObj.inventory.createdTime   = $((get-date -format u).replace('Z',''));
            # $hostObj.inventory.deleteDate    = '0000-00-00 00:00:00'
            $hostObj.inventory.sysman        = $compSys.Vendor; #manufacturer
            $hostObj.inventory.sysproduct    = $compSys.Name; #model
            $hostObj.inventory.sysversion    = $compSys.Version;
            $hostObj.inventory.sysserial     = $compSys.IdentifyingNumber;
            if ($compSys.UUID -notmatch "12345678-9012-3456-7890-abcdefabcdef" ) {
                $hostObj.inventory.sysuuid       = $compSys.UUID;
            } else {
                $hostObj.inventory.sysuuid       = ($compSys.Qualifiers | Where-Object Name -match 'UUID' | Select-Object -ExpandProperty Value);
            }
            $hostObj.inventory.systype       = $case.chassistype; #device form factor found chassistype member of $case but it references a list that hasn't been updated anywhere I can find. i.e. returns 35 for a minipc but documented list only goes to 24
            $hostObj.inventory.biosversion   = $bios.name;
            $hostObj.inventory.biosvendor    = $bios.Manufacturer;
            $hostObj.inventory.biosdate      = $(get-date $info.BiosReleaseDate -Format d);
            $hostObj.inventory.mbman         = $baseBoard.Manufacturer;
            $hostObj.inventory.mbproductname = $baseBoard.Product;
            $hostObj.inventory.mbversion     = $baseBoard.Version;
            $hostObj.inventory.mbserial      = $baseBoard.SerialNumber;
            $hostObj.inventory.mbasset       = $baseBoard.Tag;
            $hostObj.inventory.cpuman        = $cpu.Manufacturer;
            $hostObj.inventory.cpuversion    = $cpu.Name;
            $hostObj.inventory.cpucurrent    = "Current Speed: $($cpu.currentClockSpeed) MHz";
            $hostObj.inventory.cpumax        = "Max Speed $($cpu.MaxClockSpeed) MHz";
            $hostObj.inventory.mem           = "MemTotal: $($comp.TotalPhysicalMemory) kB";
            $hostObj.inventory.hdmodel       = $hdd.Model;
            $hostObj.inventory.hdserial      = $hdd.SerialNumber;
            $hostObj.inventory.hdfirmware    = $hdd.FirmareRevision;
            $hostObj.inventory.caseman       = $case.Manufacturer;
            $hostObj.inventory.casever       = $case.Version;
            $hostObj.inventory.caseserial    = $case.SerialNumber;
            $hostObj.inventory.caseasset     = $case.SMBIOSAssetTag;
            $hostObj.inventory.memory        = "$([MATH]::Round($(($comp.TotalPhysicalMemory) / 1GB),2)) GiB";
            $jsonData = $hostObj.inventory | ConvertTo-Json;
            return $jsonData;
        }
    }


}
