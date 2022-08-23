function Get-LastImageTime {
    <#
    .SYNOPSIS
    Prompts for a serial number, finds the host by that serial number, and returns a string showing the last image time of that host
    
    .DESCRIPTION
    Searches the imaging log for the hostid and returns the last entries start time and image used in a descriptive string
    
    .PARAMETER serialNumber
    The serialnumber to search for, if not specified, it will prompt for input with readhost
    
    .EXAMPLE
    Get-LastImageTime

    Will prompt you to scan/type in a serialnumber (i.e. via barcode).
    Lets say you scan/input 12345678, if that serialnumber belong to a host named "test" it would display a string like this
    "Serial number 12345678 belongs to host test, it was last imaged at 2022-08-18 12:19:38 with the image Win-10-21H2"
    And return the full object of the host's imaging log

    .EXAMPLE
    Get-LastImageTime 
    
    .NOTES
    Implemented as part of a feature request found in the forums here https://forums.fogproject.org/post/146276
    #>
    [CmdletBinding(DefaultParameterSetName="bySN")]
    param ( 
        [parameter(ParameterSetName='bySN')]
        $serialNumber, #scan the barcode input into powershell
        [parameter(ParameterSetName='byHostId')]
        $hostId,
        [parameter(ParameterSetName='byHost')]
        $fogHost,
        [parameter(ParameterSetName='byHost')]
        [switch]$currentHost
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            bySN {
                Write-Verbose "Getting host by serial number" 
                if (!$serialNumber) {
                    $serialNumber = (Read-Host -Prompt "Scan Serial Number barcode")
                }
                $fogHost = Get-FogHost -serialNumber $serialNumber;
                $HostID = $fogHost.id;
            }
            byHostID {
                Write-Verbose "Getting host by id"
                $fogHost = Get-FogHost -hostID $hostId;
            }
            byHost {
                if (!$fogHost) {
                    Write-Verbose "getting host of current machine"
                    $fogHost = (Get-FogHost)
                }
                $HostID = $fogHost.id
            }
        }
        
        $imageLog = (get-fogobject -type object -coreObject imaginglog).imagingLogs # get the image history log
        $hostLogs = $imageLog | where-object hostid -eq $HostID # get the image history logs for the given host
        $hostLog = $hostLogs[-1] # select the last/most recent log
        #return a string of the information about the serial number
        "Serial number $serialNumber belongs to host $($fogHost.name), it was last imaged at $($hostLog.start) with the image $($hostLog.image)" | Out-Host
        return $hostLog;
    }
}