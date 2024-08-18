function Send-FogWolTask {
    <#
    .SYNOPSIS
    Sends a wake on task to a given host by host object gotten with get-foghost or by the name of the host
    
    .DESCRIPTION
    Creates a new fog task of id 14 for a wake on lan task. Will cause fog to send a magic packet to the 
    mac addresses registered for the given host.
    
    .PARAMETER hostObj
    The foghost object gotten with get-foghost
    
    .PARAMETER computername
    The name of the computer to get the fog host of 
    
    .EXAMPLE
    Send-FogWolTask -computername "some-computer"

    Will send a magic computer to the computer some-computer from the fog server;

    .EXAMPLE
    $sleepers = (Get-foghosts | ? name -in ((Get-ADComputer -Filter '*' -SearchBase 'ou=someOU,dc=company,dc=local').name)); $sleepers | % {Send-FogWolTask -hostObj $_}

    Will find the names of the computers in the given ou via the distinguished name string in the searchbase param.
    It will find the fog host objects that match those names and put them in the $sleepers variable
    It will go through each of the $sleepers and send a wake on lan task
    
    .NOTES
    Created per this forum post https://forums.fogproject.org/topic/16867/api-wake-on-lan?_=1686084315380
    #>
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName='byHostObject')]
        $hostObj,
        [Parameter(ParameterSetName='byname')]
        $computername
    )
    if ($PSCmdlet.ParameterSetName -eq 'byHostObject') {
        $hostID = $hostObj.id
    } else {
        $hostID= (get-foghost -hostName $computername).id
    }
    $jsonData = @{
        taskTypeID = "14";
        wol = "1";
        other2 = "-1";
        other4 = "1";
        isActive = "1;"
    }

    return New-FogObject -type objecttasktype -coreTaskObject host -jsonData ($jsonData | ConvertTo-Json) -IDofObject $hostID
}