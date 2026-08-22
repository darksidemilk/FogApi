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
        #$env:HOSTNAME is a bash convenience variable that is not exported to child processes, so it
        #is routinely empty under systemd, cron or 'pwsh -c' - resolve the hostname properly instead
        $localHostName = try { [System.Net.Dns]::GetHostName() } catch { $env:HOSTNAME }
        if (($IsLinux -or $IsMacOS) -AND ($localHostName -match (Get-FogServerSettings).fogserver) -AND ([string]::IsNullOrEmpty($exportPath))) {
            "This is linux, is the fogserver set in the api settings and no export path was given" | Out-Host;
            "Assuming you want to create a /images/imageDefinitions folder for migrating your fog server images to another server" | out-host;
            $exportPath = "/images/imageDefinitions"
            if (!(Test-Path $exportPath)) {
                #New-Item, not mkdir - this branch only ever runs on a linux fog server, where
                #mkdir is the native binary rather than the powershell function
                New-Item -ItemType Directory -Force -Path $exportPath | Out-Null;
            }
        }
        #get current image definitions from fog server
        $images = Get-FogImages;
        #Get any files currently in the export path
        #Join-Path, not "$exportPath\*.json" - this function's whole reason to exist is running on a
        #linux fog server, where a backslash is a literal filename character. It was writing files
        #named 'imageDefinitions\Win10.json' into the parent directory and this scan never matched
        #them, so every run re-exported everything
        $curExportFiles = (Get-ChildItem (Join-Path $exportPath '*.json'));
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
                    $_ | ConvertTo-Json | Out-File -Encoding oem -FilePath (Join-Path $exportPath "$($_.name).json") -force
                } else {
                    Write-Verbose "no need to export $($_.name) the exported definition is up to date"
                }
            } else {
                $_ | ConvertTo-Json | Out-File -Encoding oem -FilePath (Join-Path $exportPath "$($_.name).json")
            }
        }


    }
    
}