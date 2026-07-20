function Set-FogHostImage {
    <#
    .SYNOPSIS
    Function to set a given image object to a host by its id
    
    .DESCRIPTION
    Function to set a given image object to a host by its id
    Will be expanded for better usability in the future
    
    .PARAMETER hostID
    the host id to set an image on 
    
    .PARAMETER fogImage
    the image object gotten from get-fogimages

    .EXAMPLE
    $foghost = get-foghost -hostid 42; $imageName = 'Windows 10'; $fogImages = Get-FogImages; Set-FogHostImage -hostId $fogHost.id -fogImage ($fogImages | Where-Object name -eq $imageName)

    Will set the image with the name of "Windows 10" to the host with the id of 42

    Expected output:
    { "imageID": 3 }


    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true)]
        $hostID,
        [parameter(ValueFromPipeline=$true)]
        $fogImage
    )
        
    process {
         $jsonImageData = $fogimage | select-object @{N="imageID";E={$_.id}} | convertto-json
         $updatedHost = Set-FogObject -type object -coreObject host -IDofObject "$($hostid)" -jsonData $jsonImageData
         return $updatedHost;
    }
    
}