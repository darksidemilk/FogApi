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

    .PARAMETER TaskRequest
    A task request body, from New-FogTaskRequest or as a hashtable, used as the
    base for the task this queues. Anything it does not set keeps the wake-on-lan
    defaults below. An escape hatch for a field this cmdlet does not expose.
    
    .EXAMPLE
    Send-FogWolTask -computername "MeowMachine"

    Will send a magic computer to the computer MeowMachine from the fog server;

    Expected output:
    { "id": 501, "success": true }

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
        [Parameter(ParameterSetName='byHostObject',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        $hostObj,
        [Parameter(ParameterSetName='byname')]
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
        [string]$computername,
        [Parameter(ParameterSetName='byHostObject')]
        [Parameter(ParameterSetName='byname')]
        [FogTaskRequest]$TaskRequest
    )
    process {
        if ($PSCmdlet.ParameterSetName -eq 'byHostObject') {
            if ($null -ne $_) {
                $hostObj = $_;
            }
            $hostID = $hostObj.id
        } else {
            $hostID= (get-foghost -hostName $computername).id
        }
        # Was a hand-built hashtable that sent isActive as "1;" -- a stray
        # semicolon inside the string, on the wire, since this cmdlet was
        # written. It also sent other2="-1" and other4="1" beside wol, believing
        # those were the FOG 1.5 spelling. They are scheduledtask columns, and
        # neither 1.5's nor 1.6's Route::task() reads them.
        #
        # other2 is the scheduledtask column for deploySnapins, so translating
        # it would have set deploySnapins=-1 and made every wake-on-lan task
        # also deploy every snapin assigned to the host. The field was inert
        # before, so it stays out: this queues a wake, and nothing else.
        $request = if ($PSBoundParameters.ContainsKey('TaskRequest')) { $TaskRequest } else { [FogTaskRequest]::new() }
        if ($null -eq $request.taskTypeID) { $request.taskTypeID = 14 }
        if ($null -eq $request.wol)        { $request.wol = $true }
        if ($null -eq $request.extra)      { $request.extra = @{ isActive = 1 } }

        return New-FogObject -type objecttasktype -coreTaskObject host -jsonData $request.ToJson() -IDofObject $hostID
    }
}