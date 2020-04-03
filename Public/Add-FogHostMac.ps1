function Add-FogHostMac {
<#
    .SYNOPSIS
    Adds a given macaddress to a host of a given ID
    
    .DESCRIPTION
    Adds a given macaddress to a host of a given ID
    
#>
    
    [CmdletBinding()]
    param ( 
        $hostID,
        $macAddress,
        [switch]$primary
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
        $newMac = @{
            hostID       = "$hostID"
            mac          = $macAddress
            description  = " "
            pending      = 0
            primary      = 0
            clientIgnore = 0
            imageIgnore  = 0
        }
        if ($primary) {
            $newMac.Primary = 1;
        }
        return New-FogObject -type object -coreObject macaddressassociation -jsonData ($newMac | ConvertTo-Json)
    }
    
}
