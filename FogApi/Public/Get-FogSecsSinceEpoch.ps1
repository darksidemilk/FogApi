function Get-FogSecsSinceEpoch {
    <#
    .SYNOPSIS
    Gets seconds since 1970 epoch
    
    .DESCRIPTION
    Gets seconds since 1970 epoch to give the unix time value
    
    .PARAMETER scheduleDate
    the date to get the unixtime of defaults to current datetime
    
    .EXAMPLE
    Get-SecsSinceEpoch

    returns the unixtime value of the current time 
    
    .NOTES
    Created to be used with creating scheduled tasks in fog
    #>
    param (
        $scheduleDate = (Get-Date)
    )
        process {
            $EpochDiff = New-TimeSpan "01 January 1970 00:00:00" $($scheduleDate)
            $EpochSecs = [INT] $EpochDiff.TotalSeconds - [timezone]::CurrentTimeZone.GetUtcOffset($(get-date)).totalseconds
            return $EpochSecs
        }
}