function Get-LastImageTime {
    <#
    .SYNOPSIS
    Prompts for a serial number, finds the host by that serial number, and returns a string showing the last image time of that host
    
    .DESCRIPTION
    Returns the most recent imaging entry's created time and image name in a descriptive string.
    imagingLog was retired in FOG 1.6 (ADR 0022); taskLog carries the image name now, so this reads
    taskLog, asks the server for that host's rows only, and keeps the ones that name an image.
    Requires a FOG 1.6 server.
    
    .PARAMETER serialNumber
    The serialnumber to search for, if not specified, it will prompt for input with readhost if none is given

    .PARAMETER hostId
    Specify the hostid to get the image history for

    .PARAMETER fogHost
    specify the fog host object to get the last history for

    .PARAMETER currentHost
    switch param to get the current host's foghost object and return the last image time
    
    .EXAMPLE
    Get-LastImageTime

    Will prompt you to scan/type in a serialnumber (i.e. via barcode).
    Lets say you scan/input 12345678, if that serialnumber belong to a host named "test" it would display a string like this
    "Serial number 12345678 belongs to host test, it was last imaged at 2026-08-18 12:19:38 with the image Win-10-21H2"
    And return the full taskLog row for that imaging event

    .EXAMPLE
    Get-LastImageTime -currentHost
    
    Will get the current computer in fog and return its most recent imaging taskLog row.
    Will also output a descriptive string, i.e. if the hostname is test-pc
    hostname is test-pc, it was last imaged at 2026-08-18 12:19:38 with the image Win-10-21H2

    .EXAMPLE
    Get-LastImageTime -hostID 42

    Will get the foghost with the id 42 and return the last imaging entry in its task log

    Expected output:
    { "id": 1, "hostID": 42, "hostName": "MeowMachine", "taskTypeName": "Deploy", "imageName": "Win-10-21H2", "createdTime": "2026-08-18 12:19:38" }

    .EXAMPLE
    Get-LastImageTime -fogHost (Get-FogHost -hostID 42)

    Will put the last imaging history entry for the given host object.
    That result's properties can then be used in other operations

    Expected output:
    { "id": 1, "hostID": 42, "hostName": "MeowMachine", "taskTypeName": "Deploy", "imageName": "Win-10-21H2", "createdTime": "2026-08-18 12:19:38" }
    
    .NOTES
    Implemented as part of a feature request found in the forums here https://forums.fogproject.org/post/146276
    #>
    [CmdletBinding(DefaultParameterSetName="bySN")]
    param ( 
        [parameter(ParameterSetName='bySN')]
        $serialNumber, #scan the barcode input into powershell
        [parameter(ParameterSetName='byHostId')]
        $hostId,
        [parameter(ValueFromPipeline=$true,ParameterSetName='byHost')]
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
                $HostID = $fogHost.id;
            }
            byHost {
                if ($currentHost -or ($null -eq $fogHost)) {
                    Write-Verbose "getting host of current machine"
                    $fogHost = (Get-FogHost)
                }
                $HostID = $fogHost.id
            }
        }

        # imagingLog was retired in FOG 1.6 (ADR 0022): it recorded the same
        # events taskLog already did, in the same place, and the one fact it held
        # alone -- which image ran -- is now taskLog.imageName. So the history
        # comes from taskLog.
        #
        # Filtered server side. /tasklog/search/{item} still cannot help -- search
        # matches a name column and taskLog has none, which is why the document
        # correctly does not advertise search for it -- but the list route takes a
        # column filter, and hostID is one of taskLog's declared fields. FOG only
        # began ADVERTISING that filter in 1.6.0-beta.3894 (FOGProject/fogproject
        # b25193faf); the route itself has always honoured it, so this works
        # against older 1.6 servers too.
        #
        # This previously listed the whole table and filtered with Where-Object,
        # which had a failure worse than being slow: the unpaged list is capped at
        # the server's MAX_ROWS (10000) and truncates SILENTLY, so on a server with
        # more taskLog rows than that, the rows for this host might never be in the
        # page at all and the function would report the wrong "last imaged" time,
        # or none, with no indication anything had been dropped.
        $logs = (Get-FogObject -type object -coreObject tasklog -Filter @{ hostID = $HostID }).data;

        # imageName is still filtered here rather than server side. The filter ANDs
        # exact matches and there is no "is not empty" operator, so "rows that name
        # an image" is not something it can express -- but this now runs over one
        # host's rows instead of the entire table.
        $hostLogs = @($logs | Where-Object {
            -not [string]::IsNullOrWhiteSpace($_.imageName)
        });
        if (!$hostLogs) {
            Write-Warning "No imaging logs found for host $($fogHost.name)!"
            return $null;
        } else {
            # Sorted rather than taking [-1]: that assumed the server returns
            # rows in ascending time order, which nothing in the API promises.
            $hostLog = ($hostLogs | Sort-Object { [datetime]$_.createdTime })[-1];
            #return a string of the information about the serial number
            if ($serialNumber) {
                "Serial number $serialNumber belongs to host $($fogHost.name), it was last imaged at $($hostLog.createdTime) with the image $($hostLog.imageName)" | Out-Host
            } else {
                "hostname is $($fogHost.name), it was last imaged at $($hostLog.createdTime) with the image $($hostLog.imageName)" | Out-Host
            }
            return $hostLog;
        } 
    }
}