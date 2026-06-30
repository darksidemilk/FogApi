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
    $foghost = get-foghost -hostid 1234; $imageName = 'MyImage'; $fogImages = Get-FogImages; $fogHost = Set-FogHostImage -hostId $fogHost.id -fogImage ($fogImages | Where-Object name -eq $imageName)

    Will set the image with the name of MyImage to the host with the id of 1234

    
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