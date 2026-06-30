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

    .PARAMETER fogHostID
    The fogHostID parameter allows you to pass a host ID to reset the encryption data for that host.

    .PARAMETER restartSvc
    The restartSvc switch will restart the fog service
    forcing a more immediate re-encryption and connection. This currently only works when used on the local computer
    you are resetting.

    .EXAMPLE
    Reset-HostEncryption -fogHostID 1234 -restartSvc

    This example resets the encryption data for the host with ID 1234 and restarts the fog service to force a re-encryption.

    .EXAMPLE
    Reset-HostEncryption -fogHost (Get-FogHost -hostID 1234)

    This example resets the encryption data for the host with ID 1234 using the host object returned from Get-FogHost.

    .EXAMPLE
    Reset-HostEncryption -restartSvc

    This example resets the encryption data for the current host running the command and restarts the fog service to force a re-encryption.
    
#>
    
    [CmdletBinding()]
    [Alias('Reset-FogHostEncryption')]
    param (
        [parameter(ValueFromPipeline=$true,ParameterSetName='HostObject')]
        $fogHost = (Get-FogHost),
        [parameter(ParameterSetName='HostID')]
        $fogHostID,
        [parameter(ParameterSetName='HostObject')]
        [parameter(ParameterSetName='HostID')]
        [switch]$restartSvc
     )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'HostID') {
            $fogHost = Get-FogHost -hostID $fogHostID;
        } else {
            if ($null -ne $_) {
                $fogHost = $_;
            }
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
