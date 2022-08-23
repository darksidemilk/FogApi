function Get-FogImages {
    <#
    .SYNOPSIS
    Returns an object of the images defined in your fogserver
    
    .DESCRIPTION
    Returns the images from your fog server with all their properties
    
    .EXAMPLE
    $images = Get-FogImages; $images | select id,name

    Gets all the fog images and then lists them with just the image id and names
    
    #>
    [CmdletBinding()]
    param (  )
    
    process {
        return (Get-FogObject -type object -coreObject image | select-object -ExpandProperty images);
    }
}