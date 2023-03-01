function Resolve-HostID {
    <#
    .SYNOPSIS
    Validate the input is a hostid integer
    
    .DESCRIPTION
    Tests if the value can be cast as an int, if not then see if it is the hostname, if not that, see if it is the host object, otherwise return null
    
    .PARAMETER hostID
    the hostid to validate, if none is given, will get the host object of the current host
    
    #>
    [CmdletBinding()]
    param (
        $hostID = (Get-foghost).id
    )
    
    
    process {
        if ($hostID.gettype().name -ne "Int32"){
            try {
                $check = [int32]$hostID
                Write-Verbose "checking if hostid is an int: '$check' yes it is"
            } catch {
                if ($hostID.gettype().name -eq "string") {
                    $hostID = (Get-FogHost -hostname $hostID).id
                } elseif($hostID.gettype().name -eq "PSCustomObject") {
                    if ($hostID.id) {
                        $hostID = $hostID.id
                    } else {
                        $hostID = $null;
                    }
                } else {
                    $hostID = $Null;
                }
                if ($null -eq $hostID) {
                    Write-Error "Please provide a valid foghost object, hostid or hostname, returning null for hostid"
                }
            }
        }
        if ($null -ne $hostID) {
            if ($null -eq (Get-foghost -hostID $hostID)) {
                Write-Error "hostid $hostID does not exist in your fog hosts! returning null!"
                $hostID = $null;
            }
        }
        return $hostID;
    }
    
}