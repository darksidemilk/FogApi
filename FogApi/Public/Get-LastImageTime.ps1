function Get-LastImageTime {
    <#
    .SYNOPSIS
    Prompts for a serial number, finds the host by that serial number, and returns a string showing the last image time of that host
    
    .DESCRIPTION
    Searches the task log for the hostid and returns the most recent imaging entry's created time and image name in a
    descriptive string. imagingLog was retired in FOG 1.6 (ADR 0022); taskLog carries the image name now, so this reads
    taskLog and keeps only the rows that name an image.
    
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
        # Listed, not searched, even though /tasklog/search/{item} is documented.
        # That route cannot work here: Route::search() is built on unisearch, and
        # unisearch deliberately skips any entity with no `name` column -- taskLog
        # has none, so the search always answers recordsFiltered:0 no matter what
        # is asked for. Verified against a live 1.6 server with rows that plainly
        # matched. Twenty route classes are advertised with a search route they
        # cannot honour; that belongs upstream in OpenAPI::_paths(), not worked
        # around here.
        #
        # So this pages the table and filters client side. Nothing deletes taskLog
        # rows and it records every task state change rather than only imaging, so
        # the cost grows with server age. A server-side filter is what this really
        # wants; the list route takes only start/length/expand today.
        $logs = (Get-FogObject -type object -coreObject tasklog).data;
        $hostLogs = @($logs | Where-Object {
            $_.hostID -eq $HostID -AND -not [string]::IsNullOrWhiteSpace($_.imageName)
        });
        if (!$hostLogs) {
            Write-Warning "No imaging logs found for host $($fogHost.name)!"
            return $null;
        } else {
            $hostLog = $hostLogs[-1] # select the last/most recent log
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