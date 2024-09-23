$ErrorActionPreference = 'Stop'

#uninstall just this version of the module from system level paths

$toolsDir = Split-Path -parent $MyInvocation.MyCommand.Definition
#include the additional functions for install
Import-Module "$toolsDir\functions.psm1"

$moduleName = $env:chocolateyPackageName 
$moduleVersion = $env:ChocolateyPackageVersion

Remove-Module -Name $moduleName -force -ea 0;
Remove-ModuleManually -modulename $moduleName -moduleversion $moduleVersion;
