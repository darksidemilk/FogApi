$ErrorActionPreference = 'Stop'

#uninstall just this version of the module from system level paths

$toolsDir = Split-Path -parent $MyInvocation.MyCommand.Definition
#include the additional functions for install
Import-Module "$toolsDir\functions.psm1"

$moduleName = $env:chocolateyPackageName 
$moduleVersion = $env:ChocolateyPackageVersion

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
if (($pp.NoRemove)) {
    Write-Warning "'NoRemove' was passed into uninstall, this parameter is only for install, this will be ignored"
    $pp.NoRemove = $false;
} else {
    $pp.NoRemove = $false;
}
if (!($pp.RemoveAll)) {
    $pp.RemoveAll = $false;
} else {
    $pp.RemoveAll = $true;
}

Remove-Module -Name $moduleName -force -ea 0;
if ($pp.RemoveAll) {
    "Remove all specified, finding all versions of $modulename and removing them, is PS7Only or PS5Only is specified then only all versions from that path will be removed" | out-host;
    Remove-ModuleManually -modulename $moduleName -ps5only:$pp.PS5Only -ps7only:$pp.PS7Only -allversions;
} else {
    "Uninstalling module $modulename of version $moduleVersion" | out-host;
    Remove-ModuleManually -modulename $moduleName -moduleversion $moduleVersion -ps5only:$pp.PS5Only -ps7only:$pp.PS7Only;
}
