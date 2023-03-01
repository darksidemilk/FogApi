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

    .PARAMETER forceUpdate
    Set this switch param if you need this mac to be force specified to the specified host if the mac is already assigned to another host.
    
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
        [switch]$ignoreMacForImaging,
        [switch]$forceUpdate
    )

    process {
        $hostID = Resolve-HostID $hostID
        if ($null -ne $hostID) {
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
            $macExists = Get-FogMacAddresses | Where-Object mac -eq $macAddress
            if ($null -ne $macExists) {
                if ($forceUpdate) {
                    Write-Warning "this mac already exists in fog!, updating it to be assigned to this host instead"
                    Write-Verbose "Old mac definition was $($macExists | out-string). Updating to $($newMac | Out-String)";
                    return Update-FogObject -type object -coreObject macaddressassociation -jsonData ($newMac | ConvertTo-Json) -IDofObject $macExists.id
                } else {
                    Write-Warning "This mac already exists in fog! It is attached to the host named: $((get-foghost -hostID $macExists.hostID).name)"
                }
    
            } else {
                return New-FogObject -type object -coreObject macaddressassociation -jsonData ($newMac | ConvertTo-Json)
            }
        } else {
            Write-Error "provided hostid was invalid!"
            return $null;
        }
    }
    
}
