function Repair-FogSnapinAssociations {
    <#
    .SYNOPSIS
    Finds any invalid snapin associations and removes them from the server
    
    .DESCRIPTION
    Finds any snapin associations that have a snapinID or hostID of 0 or a negative number or that have a snapin or host id that doesn't exist in the server
    Displays the ones that will be deleted if any are found and then removes them. 
    You can use -debug to pause and display each association before it is deleted (assuming your $debugpreference variable is set to 'inquire')
    
    .EXAMPLE
    Repair-FogSnapinAssociations

    'Example of output when there are associations to remove'
    These snapin assoiciations have an invalid snapinID either of 0 or -1 or an id that doesn't belong to any snapins in the server and will be removed:

    id    hostID snapinID
    --    ------ --------
    9289  1809   0
    9985  1866   0
    10000 2091   0

    These snapin assoiciations have an invalid hostID of either 0 or -1 or other negative number, or have a hostid that doesn't belong to any host and will be removed:

    id   hostID snapinID
    --   ------ --------
    8281 1787   103
    8513 1960   103
    8597 1935   635
    8598 1935   629
    8599 1933   639
    8600 1935   69
    8601 1935   137
    9353 0      681
    9354 0      684

    Snapin Association repair complete!
        
    .NOTES
    When running Get-FogHostAssociatedSnapins, if associations with invalid snapin ids are found, 
    #>
    [CmdletBinding()]
    param (
        
    )
    
    process {
        #get all associations on the server
        $AllAssocs = Get-FogSnapinAssociations;
        #find any that have a snapinID of 0 or -1 or any negative number that would also be invalid and find any snapin associations with an id that doesn't exist
        $allsnapinIDs = (Get-FogSnapins).id | Sort-Object;
        $invalidSnapinID = $AllAssocs | Where-Object { ($_.snapinID -le 0) -or ($_.snapinID -notin $allsnapinIDs)}
        if ($null -ne $invalidSnapinID) {
            "These snapin assoiciations have an invalid snapinID either of 0 or -1 or an id that doesn't belong to any snapins in the server and will be removed:`n$($invalidSnapinID | out-string)" | out-host;
            $invalidSnapinID | ForEach-Object {
                Write-Verbose "Removing association $($_ | out-string)"
                Write-Debug "Removing association $($_ | out-string)"a
                Remove-FogObject -type object -coreObject snapinassociation -IDofObject $_.id
            }
            #refresh association list after removing some invalids
            $AllAssocs = Get-FogSnapinAssociations;
        } else {
            "No associations with invalid snapinID found" | out-host;
        }
        #get all current fog host IDs for testing if the hostid is a host that exists
        $AllHostIDs = (Get-FogHosts).id | Sort-Object
        #find any associations with a hostID of 0 or -1 or where the hostid is not a host 
        $invalidHostID = $AllAssocs | Where-Object { ($_.hostID -le 0) -OR ($_.hostid -notin $AllHostIDs) }
        if ($null -ne $invalidHostID) {
            "These snapin assoiciations have an invalid hostID of either 0 or -1 or other negative number, or have a hostid that doesn't belong to any host and will be removed:`n$($invalidHostID | out-string)" | out-host;
            $invalidHostID | ForEach-Object {
                Write-Verbose "Removing association $($_ | out-string)"
                Write-Debug "Removing association $($_ | out-string)"
                Remove-FogObject -type object -coreObject snapinassociation -IDofObject $_.id
            }
        } else {
            "No Invalid hostid's found in snapin associations"
        }
        "Snapin Association repair complete!" | out-host;

    }
    
}