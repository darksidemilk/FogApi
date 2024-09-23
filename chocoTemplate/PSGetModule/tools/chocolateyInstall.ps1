$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -parent $MyInvocation.MyCommand.Definition
$sources = "$toolsDir\files"
#include the additional functions for install
Import-Module "$toolsDir\functions.psm1"

$moduleName = $env:chocolateyPackageName 
$moduleVersion = $env:ChocolateyPackageVersion


# module may already be installed outside of Chocolatey, if so get it out of the current session
Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue

$destinationRootPath = New-Object -TypeName 'System.Collections.generic.list[System.Object]';

#ps 5.1 installed system mods
$destinationRootPath.add((Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules\$moduleName"))
#ps 7 installed system mods
$destinationRootPath.add((Join-Path -Path $env:ProgramFiles -ChildPath "PowerShell\Modules\$moduleName"))
 
"Installing $modulename version $moduleVersion in both pwsh 7+ and windows powershell 5.1 system paths" | out-host;
ForEach ($dest in $destinationRootPath) {
    $destPath = "$dest\$moduleVersion"
    Write-Verbose "Installing '$modulename' of version '$moduleVersion' to '$destPath'."
    # check destination path exists if force, remove it, otherwise don't overwrite existing path
    if (!(Test-Path -Path $destPath) -OR ($env:chocolateyForce)) {
        if ((Test-Path -Path $destPath) -and ($env:chocolateyForce)) {
            Write-Verbose "Force is specified, removing existing version at $destpath"
            if ($destPath -match "WindowsPowershell") {
                Remove-ModuleManually -modulename $modulename -moduleversion $moduleVersion -ps5only
            } else {
                Remove-ModuleManually -modulename $modulename -moduleversion $moduleVersion -ps7only
            }
        }
        $packageargs = @{
            packagename = $env:chocolateyPackageName
            destination = $destPath
            FileFullPath = "$sources\$modulename.$moduleversion.zip"
        }
        #unzip module to install path
        $installedpath = Get-ChocolateyUnzip @packageargs;
        Write-Verbose "Installed to $($installedpath)"
        #import the cli xml and set the install location.
        $psmodinfoxml = Import-Clixml "$installedPath\PSGetModuleInfo.xml";
        $psmodinfoxml.InstalledLocation = $installedPath;
        $psmodinfoxml | Export-Clixml -Path "$destPath\PSGetModuleInfo.xml" -Force;
        #set to hidden 
        (get-item "$destPath\PSGetModuleInfo.xml").Attributes = "Hidden";
    } else {
        Write-Verbose "Path $destPath already exists! Not overwriting existing install of same version"
    }
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
            $oldVersions | ForEach-Object {
                $oldVersion = $_.fullname | Split-Path -leaf;
                Remove-ModuleManually -modulename $moduleName -moduleVersion $oldVersion;
            }
        }
    }
}

#clean up chocolatey local lib path, remove the module files and the psgemoduleinfo.xml files keeping only the nuspec/nupkg and chocolatey scripts in the programdata\chocolatey\lib\modulename path
if (Test-Path $sources) {
    Set-Location $home;
    Remove-Item -Path $sources -Force -Recurse -EA stop;
}
