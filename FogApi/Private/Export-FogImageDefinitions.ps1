function Export-FogImageDefinitions {
    <#
    .SYNOPSIS
    Create an export of image definitions for later import for syncing across sites or migrating to a new server
    
    .DESCRIPTION
    Creates .json files of image definitions on your server
    
    .PARAMETER exportPath
    Parameter description
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        $exportPath
    )
    
    
    process {
        if ($IsLinux -AND ($env:HOSTNAME -match (Get-FogServerSettings).fogserver) -AND ([string]::IsNullOrEmpty($exportPath))) {
            "This is linux, is the fogserver set in the api settings and no export path was given" | Out-Host;
            "Assuming you want to create a /images/imageDefinitions folder for migrating your fog server images to another server" | out-host;
            $exportPath = "/images/imageDefinitions"
            if (!(Test-Path $exportPath)) {
                mkdir $exportPath;
            }
        }
        #get current image definitions from fog server
        $images = Get-FogImages;
        #Get any files currently in the export path
        $curExportFiles = (Get-ChildItem $exportPath\*.json);
        $curExports = New-Object System.Collections.Generic.list[system.object];
        $curExportFiles | ForEach-Object {
            $curExports.add((Get-content $_.FullName | ConvertFrom-Json))
        }
        # $imagesToExport = New-Object System.Collections.Generic.list[system.object];
        
        $images | ForEach-Object {
            if ($_.name -in $curExports.name) {
                Write-Verbose "Image of $($_.name) already has an export, checking if it is newer"
                $curExportDate = Get-date $curExports.deployed;
                $newImageDate = Get-Date $_.deployed
                if ($newImageDate -gt $curExportDate) {
                    Write-Verbose "The image has been captured more recently than the export"
                    $_ | ConvertTo-Json | Out-File -Encoding oem -FilePath "$exportPath\$($_.name).json" -force
                } else {
                    Write-Verbose "no need to export $($_.name) the exported definition is up to date"
                }
            } else {
                $_ | ConvertTo-Json | Out-File -Encoding oem -FilePath "$exportPath\$($_.name).json"
            }
        }


    }
    
}