function Remove-UsbMac {
<#
    .SYNOPSIS
        A cmdlet that uses invoke-fogapi to remove a given list of usb mac address from a host

    .DESCRIPTION
        When a wireless device is imaged with a usb ethernet adapter, it should be removed when it's done
        
    .PARAMETER usbMacs
        a string of mac addresses like this @("01:23:45:67:89:10", "00:00:00:00:00:00")

    .PARAMETER hostname
        the hostname to remove the usb macs from, defaults to current hostname

    .EXAMPLE
        Remove-UsbMacs -fogServer "foggy" -usbMacs @("01:23:45:67:89:10", "00:00:00:00:00:00")

    .NOTES
        online version of help goes to fog forum post where the idea was conceived
        There are try catch blocks so the original working code before the get, update, and remove functions existed can remain as a fallback
        See also https://forums.fogproject.org/topic/10837/usb-ethernet-adapter-mac-s-for-imaging-multiple-hosts-universal-imaging-nics-wired-nic-for-all-wireless-devices/14
#>
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline=$true,ParameterSetName='byHost')]
        $hostObj,
        [parameter(ParameterSetName='byName')]
        [ArgumentCompleter({
            param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
            if(Test-FogVerAbove1dot6) {
                $r = (Get-FogHosts).Name

                if ($WordToComplete) {
                    $r.Where{ $_ -match "^$WordToComplete" }
                }
                else {
                    $r
                }
            }
        })]  
        [string]$hostName= "$(hostname)",
        [parameter(ParameterSetName='byName')]
        [parameter(ParameterSetName='byHost')]
        [string[]]$usbMacs
        # $macId
    )
    
    process {
        if ($null -eq $usbMacs) {
            Write-Error "no macs to remove given";
            exit;   
        }
        if ($null -ne $_) {
            $hostObj = $_;
        } else {
            $hostObj = Get-FogHost -hostName $hostname;
        }
        Write-Verbose "remove usb ethernet adapter from host $hostname on fog server $fogServer ....";
        # get the host id by getting all hosts and searching the hosts array of the returned json for the item that has a name matching the current hostname and get the host id of that item
        $hostId = $hostObj.id;
        # $hostId = ( (Invoke-FogApi -fogServer $fogServer -fogApiToken $fogApiToken -fogUserToken $fogUserToken).hosts | Where-Object name -match "$hostname" ).id;
        # With the host id get mac associations that match that host id.
        
        $macs = Get-FogMacAddresses | Where-Object hostID -match $hostID
    
        # Copy the return fixedsize json array collection to a new powershell list variable for add and remove functions
        $macList = New-Object System.Collections.Generic.List[System.Object];
        try {
            $macs.ForEach({ $macList.add($_.mac); });
        } catch {
            $macs | ForEach-Object{
                $macList.add($_.mac);
            }
        }
        # Check if any usbmacs are contained in the host's macs
        $usbMacs | ForEach-Object { #loop through list of usbMacs
            if ( $macList.contains($_) ) { # check if the usbMac is contained in the mac list of the host
                # Remove from the list so a new primary can be picked if needed
                $macList.Remove($_);

                Write-Verbose "$_ is a $usbMac connected to $hostname, checking if it is the primary...";
                $macItem = ($macs | Where-Object mac -eq $_ );

                if ( $macItem.primary -eq '1' ) {
                    Write-Verbose "It is primary, let's fix that and set $($macList[0]) to primary";
                    $macItem.primary = '0';
                    try {
                        Update-FogObject -type object -coreObject macaddressassociation -IDofObject $macItem.id -jsonData ($macItem | ConvertToJson)
                    } catch {   
                        $removePrimaryAttribute = @{
                            uriPath = "macaddressassociation/$($macItem.id)/edit";
                            Method = 'Put';
                            jsonData = ($macItem | ConvertTo-Json);
                        }
                        Invoke-FogApi @removePrimaryAttribute;
                    }

                    Write-Verbose "Primary attribute removed, setting new primary...";
                    $newPrimary = ($macs | Where-Object mac -eq $macList[0] );
                    if ($null -eq $newPrimary) {
                        Write-Verbose "host only has usbmacs, adding first non usbmac adapter";
                        $physicalMacs = (get-netadapter | select-object -expand macaddress).replace("-",":")
                        $physicalMacs = $physicalMacs | Where-Object {$_ -NotIn $usbMacs};
                        Add-FogHostMac -hostID $hostID -macAddress $physicalMacs[0] -primary;
                    } else {
                        $newPrimary.primary = '1';
                        $newPrimary.pending = '0';
                        Update-FogObject -type object -coreObject macaddressassociation -IDofObject $newPrimary.id -jsonData ($newPrimary | ConvertTo-Json)
                    }
                }

                Write-Verbose "Remove the usb ethernet mac association";
                try {
                    $result += Remove-FogObject -type object -coreObject macaddressassociation -IDofObject $macItem.id;
                } catch {
                    $removeMacAssoc = @{
                        uriPath = "macaddressassociation/$($macItem.id)/delete";
                        Method = 'Delete';
                    }
                    $result += Invoke-FogApi @removeMacAssoc;
                }
                Write-Verbose "Usb macs $usbMacs have been removed from $hostname on the $fogServer";
            }
        }
        if ($null -eq $result) {
            $result = "no usb adapters found"; #replace string if found
        }
        return $result;
    }
}
