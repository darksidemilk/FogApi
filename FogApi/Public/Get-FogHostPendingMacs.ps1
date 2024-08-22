function Get-FogHostPendingMacs {
    <#
    .SYNOPSIS
    Gets the pending macs for a given hosts
    
    .DESCRIPTION
    Gets the macs for a host and filters them to just pending ones.
    The returned object can then be approved with approve-fogpendingmac
    or denied with deny-fogpendingmac
    
    .PARAMETER hostID
    the hostid or hostname of the fog host
    
    .EXAMPLE
    Get-PendingMacsForhost -hostID 123

    gets the macs if any for foghost 123

    .EXAMPLE
    Get-PendingMacsForhost -hostID 'ComputerName'
    
    Returns the pending macs for the host with the name ComputerName

    #>
    
    [Alias('Get-PendingMacsForHost')]
    [CmdletBinding(DefaultParameterSetName='byId')]
    param (
        [parameter(ValueFromPipeline=$true,ParameterSetName='byHost')]
        $fogHost,
        [parameter(ParameterSetName='byId')]
        $hostID
    )
    
    
    process {
        if ($null -ne $_) {
            $fogHost = $_;
            $hostId = $fogHost.id;
        }
        $hostID = Resolve-HostID -hostID $hostid;
        if ($null -ne $hostID) {
            $hostMacs = Get-FogHostMacs -hostid $hostID;
            $pendingMacs = $hostMacs | Where-Object pending -eq '1';
        } else {
            Write-Error "provided hostid was invalid!"
        }
        return $pendingMacs;
    }
    
}