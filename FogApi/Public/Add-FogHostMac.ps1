function Add-FogHostMac {
<#
    .SYNOPSIS
    Adds a given macaddress to a host of a given ID
    
    .DESCRIPTION
    Adds a given macaddress to a host of a given ID, optionatlly it can be set as primary

    .PARAMETER hostID
    Can either be the id number of the host object or the name of the host in a string

    .PARAMETER macAddress
    The mac address you want to add. Should be in the format of "12:34:56:78:90"

    .PARAMETER primary
    switch parameter to set the macaddress as the primary for the host

    .PARAMETER ignoreMacOnClient
    set this switch param if you need this mac to be ignored by the fog client

    .PARAMETER ignoreMacForImaging
    Set this switch param if you need this mac to be ignored by the pxe client
    
    .EXAMPLE
    Add-FogHostMac -hostid 123 -macaddress "12:34:56:78:90" -primary

    Add the macaddress "12:34:56:78:90" of the host with the id 123 and set it as the primary mac
    
    .EXAMPLE
    Add-FogHostMac -hostID "computerName" -macaddress "12:34:56:78:90"

    Uses the hostname to find the hostid in fog then adds "12:34:56:78:90" as a secondary mac on the host
    
#>
    
    [CmdletBinding()]
    param ( 
        $hostID,
        $macAddress,
        [switch]$primary,
        [switch]$ignoreMacOnClient,
        [switch]$ignoreMacForImaging
    )

    process {
        if ($hostID.gettype().name -ne "Int32"){
            try {
                $hostID = Get-FogHost -hostname $hostID
            } catch {
                Write-Error "Please provide a valid hostid or hostname"
                exit;
            }
        }
        if ($primary) {
            $primaryVal = '1'
        } else {
            $primaryVal = '0'
        }
        if ($ignoreMacForImaging) {
            $imageIgnoreVal = '1'
        } else {
            $imageIgnoreVal = '0'
        }
        if ($ignoreMacOnClient) {
            $clientIgnoreVal = '1'
        } else {
            $clientIgnoreVal = '0'
        }
        $newMac = @{
            hostID       = "$hostID"
            mac          = "$macAddress"
            description  = " "
            pending      = '0'
            primary      = $primaryVal
            clientIgnore = $clientIgnoreVal
            imageIgnore  = $imageIgnoreVal
        }
        return New-FogObject -type object -coreObject macaddressassociation -jsonData ($newMac | ConvertTo-Json)
    }
    
}
