$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -parent $MyInvocation.MyCommand.Definition
#include the additional functions for install
Import-Module "$toolsDir\functions.psm1"

$moduleName = $env:chocolateyPackageName 
$moduleVersion = $env:ChocolateyPackageVersion

# module may already be installed outside of Chocolatey, if so get it out of the current session
Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue

#install the new version

#get all the files and folders to copy for installing the module (exclude the tools folder and chocolatey package files)
$sourcePath = New-Object -TypeName 'System.Collections.generic.list[System.Object]';
(Split-Path -Path $toolsDir -Parent) | Get-ChildItem -Exclude ".chocolateyPending","*.nuspec","*.nupkg","tools" | ForEach-Object {
    $src = $_.fullname;
    if (Test-Path $src) {
        $sourcePath.add(($src))
    }
}

<# 
#sourcepath contextual paths examples for files used to install a module
.\en-us #if present as well as any other translated languages for module docs
.\lib #if present
.\bin #if present
.\modulename.psd1
.\modulename.psm1
#>
#the above files will be installed to the default program files module install path for
#PS5 and PS7 with the addition of the psgetmoduleinfo.xml from the tools\files for the ps5 and ps7 versions;

$destinationRootPath = New-Object -TypeName 'System.Collections.generic.list[System.Object]';

#ps 5.1 installed system mods
$destinationRootPath.add((Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules\$moduleName"))

#ps 7 installed system mods
$destinationRootPath.add((Join-Path -Path $env:ProgramFiles -ChildPath "PowerShell\Modules\$moduleName"))
 
"Installing $modulename version $moduleVersion in both pwsh 7+ and windows powershell 5.1 system paths" | out-host;
ForEach ($dest in $destinationRootPath) {
    $destPath = "$dest\$moduleVersion"
    Write-Verbose "Installing '$modulename' of version '$moduleVersion' to '$destPath'."
    # check destination path exists and create if not
    if (!(Test-Path -Path $destPath)) {
        $null = New-Item -Path $destPath -ItemType Directory -Force -ea 0;
        $compare = $false;
    } else {
        Write-Verbose "Path $destPath already exists, errors on copy will be ignored"
        $compare = $true;
    }

    $sourcePath | ForEach-Object {
        #copy each source path to the current destination
        try {
            Copy-Item $_ -Destination $destPath -force -Recurse -ea stop
        } catch {
            if ($compare) {
                Write-Verbose "The module may have already been installed, ignoring errors"
            } else {
                throw "Error during copy of $($_) to $destPath!"
            }
        }
    }
    #copy the psgetmoduleinfo files for the specific powershell version paths from the files folder
    Write-Verbose "Copy PSGetModuleInfo xml"
    if ($destPath -match "\\Powershell\\Modules") {
        $psgetXmlSrc = "$toolsDir\files\PSGetModuleInfo-ps7.xml"
    } else {
        $psgetXmlSrc = "$toolsDir\files\PSGetModuleInfo-ps5.xml"
    }
    Copy-Item $psgetXmlSrc "$destPath\PSGetModuleInfo.xml" -Force
    $psgetxml = Get-Item "$destPath\PSGetModuleInfo.xml" -force;
    $psgetxml.Attributes = "Hidden"; #set the file to be hidden the same way an install from psresourceget or psget does
}


#uninstall other versions after adding the new one

Write-Verbose "Finding and uninstalling/removing any other versions of $modulename"
"Finding and removing any other versions of $modulename so only the latest is available at system level" | out-host;

ForEach ($destPath in $destinationRootPath) {
    if (Test-path $destPath) {
        Write-Verbose "Uninstalling any other versions installed at $destPath"
        Write-verbose "removing system wide versions of module, remove module version folders that aren't the current version"
        $oldVersions = (Get-ChildItem $destPath -Directory -ea 0 -Exclude $moduleVersion).FullName;
        if ($null -ne $oldVersions) {
            Write-verbose "Taking ownership of path $($_) and setting permissions to ensure clean removal";
            $oldVersions | ForEach-Object {
                $logDir = "$env:temp\logs"
                if (!(Test-Path $logDir)) {
                    mkdir $logDir -ea 0;
                }
                $takeOwn = start-process -FilePath takeown.exe -ArgumentList "/F `"$($_)`" /R /A /D Y" -wait -NoNewWindow -PassThru -RedirectStandardOutput "$logDir\takeown-$modulename-paths.log"
                Write-Verbose "Take Ownership result is $($takeOwn | out-string) - $(Get-content "$logDir\takeown-$modulename-paths.log" | out-string)"
                Remove-Item "$logDir\takeown-$modulename-paths.log" -force -Recurse -ea 0;
            }
            try {
                #give full rights to path being deleted to authenticated users
                $perms = Grant-FullRightsToPath -path $oldVersions -recurseInherit -ea stop -wa 0 -wait -NoOutHost
                Write-Verbose "grant result is $($perms | out-string)"
            } catch {
                $perms = icacls "$($oldVersions)" /inheritance:e /grant "Authenticated Users:(OI)(CI)(F)" /T /C /Q
                Write-Verbose "Grant-fullrightstopath had an error, icacls native grant result is $($perms | out-string)"
            }
            $oldVersions | Foreach-object { 
                try {
                    if (Test-Path $_) {
                        Write-Verbose "Attempting removal of old version of $moduleName installed at $($_)"
                        # "Attempting removal of old version of $moduleName installed at $($_)" | out-host;
                        [gc]::collect()
                        [gc]::waitforpendingfinalizers()
                        [gc]::collect()
                        Remove-Item -Path $_ -Force -Recurse -EA stop;
                    } else {
                        "No install for $modulename found at $($_)" | out-host;
                    }
                } catch {
                    Write-Warning "Version of $moduleName at $($_) could not be removed, most likely a dll was still loaded, attempting removal of all but dlls"
                    
                    Get-ChildItem $_ -Exclude "*.dll" -Recurse | ForEach-Object {
                        Remove-Item -path $_.FullName -force -ea 0;
                    }
                }
            }
        }
    }
}

#clean up chocolatey local lib path, remove the module files and the psgemoduleinfo.xml files keeping only the nuspec/nupkg and chocolatey scripts in the programdata\chocolatey\lib\modulename path
$sourcePath | ForEach-Object {
    remove-Item $_ -force -recurse -ea 0    
}
if (Test-Path "$toolsDir\files") {
    Set-Location $home;
    Remove-Item -Path "$toolsDir\files" -Force -Recurse -EA stop;
}
