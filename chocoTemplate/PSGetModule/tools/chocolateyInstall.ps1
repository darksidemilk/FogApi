$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -parent $MyInvocation.MyCommand.Definition
Import-Module "$toolsDir\functions.psm1"

$moduleName = '[[PackageName]]' 
$moduleVersion = '[[PackageVersion]]' #specify explicit version so install script can be run independently if needed
# $moduleVersion = $env:ChocolateyPackageVersion  # this may change so keep this here

# $savedParamsPath = Join-Path $toolsDir -ChildPath 'parameters.saved'
# $depModulesPath = Join-Path $toolsdir -ChildPath 'dependent.modules'

# module may already be installed outside of Chocolatey, if so get it out of the current session
Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue

#install the new version

#get all the files and folders to copy
$sourcePath = New-Object -TypeName 'System.Collections.generic.list[System.Object]';
#exclude the folders/files auto created by nuget in the nupkg, add all other source files/folders to sourcePath array
(Split-Path -Path $toolsDir -Parent) | Get-ChildItem -Exclude ".chocolateyPending","*.nuspec","*.nupkg" | ForEach-Object {
    $src = $_.fullname;
    if (Test-Path $src) {
        $sourcePath.add(($src))
    }
}

$destinationPath = New-Object -TypeName 'System.Collections.generic.list[System.Object]';

$destinationPath.add((Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules\$moduleName\$moduleVersion"))
$destinationPath.add((Join-Path -Path $env:ProgramFiles -ChildPath "PowerShell\Modules\$moduleName\$moduleVersion"))

"Installing $modulename version $moduleVersion in bothe pwsh 7+ and windows powershell 5.1 system paths" | out-host;
ForEach ($destPath in $destinationPath) {
    Write-Verbose "Installing '$modulename' to '$destPath'."

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
        if ($_ -ne $toolsDir) {
            try {
                Copy-Item $_ -Destination $destPath -force -Recurse -ea stop
            } catch {
                if ($compare) {
                    Write-Verbose "The module may have already been installed, ignoring errors"
                } else {
                    throw "Error during copy of $($_) to $destPath!"
                }
            }
        } else {
            #this is the tools dir, make sure to not copy the chocolatey install scripts or psgetxml sources folder to the module install folder
            try {
                Copy-Item $_ -Destination $destPath -Exclude "sources","files","chocolateyInstall.ps1","chocolateyUninstall.ps1","chocolateyBeforeModify.ps1","PSGetModuleInfo-ps5.xml","PSGetModuleInfo-ps7.xml" -force -Recurse
            } catch {
                if ($compare) {
                    Write-Verbose "The module may have already been installed, ignoring errors"
                } else {
                    throw "Error during copy of $($_) to $destPath!"
                }
            }
        }
       
    }
    #copy the psgetmoduleinfo files for the modules
    Write-Verbose "Copy PSGetModuleInfo xml"
    if ($destPath -match "\\Powershell\\Modules") {
        $psgetXmlSrc = "$toolsDir\files\PSGetModuleInfo-ps7.xml"
    } else {
        $psgetXmlSrc = "$toolsDir\files\PSGetModuleInfo-ps5.xml"
    }
    Copy-Item $psgetXmlSrc "$destPath\PSGetModuleInfo.xml" -Force
    $psgetxml = Get-Item "$destPath\PSGetModuleInfo.xml" -force;
    $psgetxml.Attributes = "Hidden";
}


#uninstall old versions before adding the new one
Write-Verbose "Finding and uninstalling/removing any old versions of $modulename"
"Finding and removing any old versions of $modulename" | out-host;

$destinationRootPath = New-Object -TypeName 'System.Collections.generic.list[System.Object]';

#ps 5.1 installed system mods
$destinationRootPath.add((Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules\$moduleName"))
#ps 7 installed system mods
$destinationRootPath.add((Join-Path -Path $env:ProgramFiles -ChildPath "PowerShell\Modules\$moduleName"))
#built in powershell mods, actually don't touch these, it's a bad plan
# $destinationRootPath += Join-Path -Path $env:ProgramFiles -ChildPath "PowerShell\7\Modules\$moduleName"
# $destinationRootPath += Join-Path -Path $env:SystemRoot -ChildPath "System32\WindowsPowerShell\v1.0\Modules\$moduleName"
#user module paths
$splitModPaths = $ENV:PSModulePath -split ';'
$splitModPaths | Where-Object { $_ -match "C:\\Users\\(.*)\\Documents\\(.*Powershell)\\Modules"} | ForEach-Object {
    $destinationRootPath.add(("$($_)\$moduleName"));
}


ForEach ($destPath in $destinationRootPath) {
    if (Test-path $destPath) {
        Write-Verbose "Uninstalling any old versions installed at $destPath"
        if (($destPath -match "C:\\Users\\(.*)\\Documents\\(.*Powershell)\\Modules\\$moduleName")) {
            Write-verbose "removing user installed versions of module, remove whole top level module folder by name"
            $oldVersions = $destPath;       
        } else {
            Write-verbose "removing system wide versions of module, remove module version folders that aren't the current version"
            $oldVersions = (Get-ChildItem $destPath -Directory -ea 0 -Exclude $moduleVersion).FullName;
        }
        if ($null -ne $oldVersions) {
            Write-verbose "Taking ownership of path $($_) and setting permissions";
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
                $perms = Grant-FullRightsToPath -path $oldVersions -recurseInherit -ea stop -wa 0 -wait -NoOutHost
                Write-Verbose "grant result is $($perms | out-string)"
            } catch {
                $perms = icacls "$($oldVersions)" /inheritance:e /grant "Authenticated Users:(OI)(CI)(F)" /T /C /Q
                Write-Verbose "Grant-fullrightstopath had an error, icacls native grant result is $($perms | out-string)"
            }
            $oldVersions | Foreach-object { 
                if ($_ -match 'config\\systemprofile\\AppData\\Local\\Microsoft\\Windows\\INetCache') {
                    $inetCache = "C:\windows\system32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache"
                    if (Test-Path $inetCache) {
                        "system profile inetcache folder detected, modules aren't actually installed here, deleting the parent folder and skipping this instance" | out-host;
                        $takeOwn = takeown.exe /F "$inetCache" /R /A /D Y
                        $takeOwn = takeown.exe /F "$inetCache\Content.IE5" /R /A /D Y
                        Write-Verbose "Ownership result is $($takeOwn | out-string)"
                        $perms = Grant-FullRightsToPath -path $inetCache -recurseInherit -ea 0 -wa 0 -NoOutHost -wait
                        Write-Verbose "perms result was $($perms | Out-String)"
                        remove-item $inetCache -Force -Recurse
                    }
                } elseif ($_ -match "AppData\\Local\\Application Data") {
                    Write-Warning "$($_) is a symlink path with no access, skip this install, this may indicate other misconfigurations! Skipping removal attempts of this path"
                } else {
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
}



#clean up chocolatey local lib path
$sourcePath | ForEach-Object {
    if ($_ -ne $toolsDir) {
        remove-Item $_ -force -recurse -ea 0
    } else {
        #is toolsdir, keep install scripts
        if (Test-Path $_) {
            $_ | Get-ChildItem -Exclude "sources","chocolateyInstall.ps1","chocolateyUninstall.ps1","chocolateyBeforeModify.ps1" | ForEach-Object {
                Remove-item $_.fullname -force -recurse -ea 0;
            }
        }
    }
}