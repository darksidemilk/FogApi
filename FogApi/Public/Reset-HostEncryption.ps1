function Reset-HostEncryption {
<#
    .SYNOPSIS
    Reset the host encryption data on a given host
    
    .DESCRIPTION
    Default to getting the current host, but can also pass the object returned from Get-FogHost
    and its parameters for any other host.
    Removes/resets the pub_key, sec_tok, and sec_time properties of a host so it can be re-encrypted by
    the fogservice to form a new connection.
    
    .PARAMETER fogHost
    Defaults to getting current host or can pass a host object

    .PARAMETER restartSvc
    The restartSvc switch will restart the fog service
    forcing a more immediate re-encryption and connection. This currently only works when used on the local computer
    you are resetting.
    
#>
    
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline=$true)]
        $fogHost = (Get-FogHost),
        [switch]$restartSvc
     )

    process {
        if ($null -ne $_) {
            $fogHost = $_;
        }
        $fogHost.pub_key = "";
        $fogHost.sec_tok = "";
        $fogHost.sec_time = "0000-00-00 00:00:00";

        try {
            $jsonData = $fogHost | Select-Object id,pub_key,sec_tok,sec-time -ea stop | ConvertTo-Json;
        } catch {
            #in 1.6, if you are looping through multiple hosts gotten with get-foghosts, they have summarized data, get the individual host record if the token properties don't exist
            $fogHOst = get-foghost -hostID $fogHost.id
            $jsonData = $fogHost | Select-Object id,pub_key,sec_tok,sec-time | ConvertTo-Json;
        }

        $result = Update-FogObject -type object -coreObject host -IDofObject $fogHost.id -jsonData $jsonData;
        if ($restartSvc) {
            Restart-Service fogservice -force;
        }
        return $result;
    }
    
}
