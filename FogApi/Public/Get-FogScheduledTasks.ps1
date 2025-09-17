function Get-FogScheduledTasks {
    <#
    .SYNOPSIS
    Gets the current Scheduled tasks, by default only active scheduled tasks
    
    .DESCRIPTION
    Gets the current Scheduled tasks and expands them into an object

    .PARAMETER all
    If specified, will return all scheduled tasks, not just active ones. This is useful for viewing historically scheduled tasks that have been completed or are no longer active.
    
    .EXAMPLE
    Get-FogScheduledTasks

    This will list any scheduled tasks and their properties

    .EXAMPLE
    Get-FogScheduledTasks | Where-Object hostid -eq (Get-Foghost -hostname "comp-name").id

    This will list any scheduled tasks for the host with the hostname "comp-name" by searching for the hostid of that computer and filtering the results to the hostid.

    #>
    
    [CmdletBinding()]
    param (
        [switch]$all
    )
    
    process {
        # $jsondata = "{`"isActive`":`"`1`"}";
        if ($all) {
            $result = get-fogobject -type object -coreObject scheduledtask
        } else {
            try {
                $result = Get-FogObject -type objectactivetasktype -coreActiveTaskObject scheduledtask -ea stop;
                if ($null -eq $result) {
                    throw "error getting scheduled tasks filtered to active in api call";
                } 
            } catch {
                Write-Warning "There was an error filtering to active scheduled tasks in the api call, getting all scheduled tasks and filtering to active locally";
                $result = Get-FogObject -type object -coreObject scheduledtask;
                $result.data = $result.data | Where-Object {
                    $_.isActive -in "1","Yes"
                }
            }
        }
        return $result.data;
    }
}