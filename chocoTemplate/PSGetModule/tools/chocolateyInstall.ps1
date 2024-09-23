$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -parent $MyInvocation.MyCommand.Definition
#include the additional functions for install
Import-Module "$toolsDir\functions.psm1"

$moduleName = $env:chocolateyPackageName 
$moduleVersion = $env:ChocolateyPackageVersion

$packageargs = @{
    packagename = $env:chocolateyPackageName
    destination = $null; #is set conditionally during a loop to install in multiple or chosen powershell paths
    Url = "https://github.com/darksidemilk/[[PackageName]]/releases/download/[[PackageVersion]]/[[PackageName]].[[PackageVersion]].IncludeXml.zip"
    Checksum = '[[checksum]]'
    ChecksumType = 'sha256'
}

$pp = Get-PackageParameters;

if (!($pp.PS7Only)) {
    $pp.PS7Only = $false;
} else {
    $pp.PS7Only = $true;
}
if (!($pp.PS5Only)) {
    $pp.PS5Only = $false;
} else {
    $pp.PS5Only = $true;
}
if (!($pp.NoRemove)) {
    $pp.NoRemove = $false;
} else {
    $pp.NoRemove = $true;
}
if ($pp.RemoveAll) {
    Write-Warning "'RemoveAll' was passed into install, this parameter is only for uninstall, this will be ignored"
    $pp.RemoveAll = $false;
} else {
    $pp.RemoveAll = $false;
}

# module may already be installed outside of Chocolatey, if so get it out of the current session
Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue

$destinationRootPath = New-Object -TypeName 'System.Collections.generic.list[System.Object]';
if($pp.PS7Only) {
    $destinationRootPath.add((Join-Path -Path $env:ProgramFiles -ChildPath "PowerShell\Modules\$moduleName"))
    "Installing $modulename version $moduleVersion in pwsh 7+ system path only" | out-host;
} elseif ($pp.PS5Only) {
    $destinationRootPath.add((Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules\$moduleName"))
    "Installing $modulename version $moduleVersion in windows powershell 5.1 system path only" | out-host;
} else {
    #ps 5.1 installed system mods
    $destinationRootPath.add((Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules\$moduleName"))
    #ps 7 installed system mods
    $destinationRootPath.add((Join-Path -Path $env:ProgramFiles -ChildPath "PowerShell\Modules\$moduleName"))
    "Installing $modulename version $moduleVersion in both pwsh 7+ and windows powershell 5.1 system paths" | out-host;
}
 
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
        $packageargs.destination = $destPath;
        #unzip module to current install path
        Install-ChocolateyZipPackage @packageargs;
        #set the install location for this install path on the PSGetModuleInfo.xml
        $psmodinfoxml = Import-Clixml "$destpath\PSGetModuleInfo.xml";
        $psmodinfoxml.InstalledLocation = $destpath;
        $psmodinfoxml | Export-Clixml -Path "$destPath\PSGetModuleInfo.xml" -Force;
        #set the PSGetModuleInfo.xml to be hidden to follow the same flow as an install from psresourceget or powershellget
        (get-item "$destPath\PSGetModuleInfo.xml").Attributes = "Hidden";
    } else {
        Write-Verbose "Path $destPath already exists! Not overwriting existing install of same version"
    }
}

#uninstall other versions after adding the new one

if (($pp.NoRemove)) {
    "'NoRemove' was specified, not removing any other installed versions of $modulename" | out-host;
} else {
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
                    Remove-ModuleManually -modulename $moduleName -moduleVersion $oldVersion -ps5only:$pp.PS5Only -ps7only:$pp.PS7Only;
                }
            }
        }
    }
}

Write-host -ForegroundColor Green -Object @"
-----------------------------------------------------------------------------
FogApi Module version $moduleVersion is installed!
It was deployed to:

$($destinationRootPath | ForEach-Object {"`t- $($_)\$moduleVersion`n"})
- Import the module with 'Import-Module FogApi'
- List commands with 'Get-Command -module FogApi'
- Use 'Set-FogServerSettings -interactive' to configure your api connection 
- Use 'Get-Help Function-name' to get inline help, append '-online' to open the web version
- Use 'Get-Help about_fogapi' for an overview of the module
-----------------------------------------------------------------------------
"@