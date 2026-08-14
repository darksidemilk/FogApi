
<#PSScriptInfo

.VERSION 1.0.0.0

.GUID 5568f4d3-8d91-4e84-ab28-1c82dc444a61

.AUTHOR JJ Fullmer

.COMPANYNAME Arrowhead Dental Lab

.COPYRIGHT 2024

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

		1.0.0.0
			Initial version

.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 builds just the module into a single psm1 

#> 
[CmdletBinding()]
Param()

Import-Module .\BuildHelpers.psm1

$moduleName = 'FogApi'
$modulePath = Join-Path $PSScriptRoot $moduleName;
$docsPth = Join-Path $PSScriptRoot 'docs';

# New-Item, not mkdir. Powershell only defines mkdir as a function on windows; on linux
# and mac it resolves to /usr/bin/mkdir, so '-EA 0' is handed to the native binary as
# '-E -A 0' and the whole build fails with "mkdir: invalid option -- 'E'"
New-Item -ItemType Directory -Force -Path $modulePath -EA 0 | Out-Null;
# New-Item -ItemType Directory -Force -Path (Join-Path $modulePath 'tools') -EA 0 | Out-Null;
# New-Item -ItemType Directory -Force -Path (Join-Path $modulePath 'docs') -EA 0 | Out-Null;
New-Item -ItemType Directory -Force -Path (Join-Path $modulePath 'lib') -EA 0 | Out-Null;
New-Item -ItemType Directory -Force -Path (Join-Path $modulePath 'bin') -EA 0 | Out-Null;
New-Item -ItemType Directory -Force -Path (Join-Path $modulePath 'Public') -EA 0 | Out-Null;
New-Item -ItemType Directory -Force -Path (Join-Path $modulePath 'Private') -EA 0 | Out-Null;
New-Item -ItemType Directory -Force -Path (Join-Path $modulePath 'Classes') -EA 0 | Out-Null;


$PublicFunctions = Get-ChildItem (Join-Path $modulePath 'Public') -Recurse -Filter '*.ps1' -EA 0;
$Classes = Get-ChildItem (Join-Path $modulePath 'Classes') -Recurse -Filter '*.ps1' -EA 0;
$PrivateFunctions = Get-ChildItem (Join-Path $modulePath 'Private') -Recurse -Filter '*.ps1' -EA 0;
# mkdir (Join-Path $PSSCriptRoot 'ModuleBuild') -EA 0;
$buildPth = Join-Path '.' '_module_build' $moduleName;
$moduleFile = Join-Path $buildPth "$moduleName.psm1";

# Create the build output folder
if (Test-Path $buildPth) {
	Remove-Item $buildPth -force -recurse;
}
New-Item -ItemType Directory -Force -Path $buildPth | Out-Null;

New-Item $moduleFile -Force | Out-Null;
# $docsPth was never defined here, so this resolved to '\en-us' and silently failed,
# shipping a built module with no external help content
$enUsSource = Join-Path $docsPth 'en-us';
if (Test-Path $enUsSource) {
	Copy-Item $enUsSource (Join-Path $buildPth 'en-us') -Recurse -Exclude '*.md';
} else {
	Write-Warning "No en-us help content found at $enUsSource, the built module will have no external help";
}
Add-Content -Path $moduleFile -Value "`$PSModuleRoot = `$PSScriptRoot";
# Emit Join-Path rather than a hardcoded backslash. On linux and mac a backslash is a literal
# filename character, so "`$PSModuleRoot\lib" produced a path that never resolved and broke the
# settings bootstrap that every command depends on. This is the copy that ships, so fixing the
# source FogApi.psm1 alone would not have fixed the published module.
if ((Get-ChildItem (Join-Path $modulePath 'lib')).count -gt 0) {
	Copy-Item (Join-Path $modulePath 'lib') (Join-Path $buildPth 'lib') -Recurse;
	Add-Content -Path $moduleFile -Value "`$script:lib = Join-Path `$PSModuleRoot 'lib'";
}
if ((Get-ChildItem (Join-Path $modulePath 'bin')).count -gt 0) {
	Copy-Item (Join-Path $modulePath 'bin') (Join-Path $buildPth 'bin') -Recurse;
	Add-Content -Path $moduleFile -Value "`$script:bin = Join-Path `$PSModuleRoot 'bin'";
}
# Copy-Item (Join-Path $modulePath 'tools') (Join-Path $buildPth 'tools') -Recurse;
Add-Content -Path $moduleFile -Value "`$script:tools = Join-Path `$PSModuleRoot 'tools'";
# Single posix test, so a branch can't be written for linux and forget mac
Add-Content -Path $moduleFile -Value "`$script:IsPosix = (`$IsLinux -or `$IsMacOS)";


#Build the psm1 file


#Add Classes
if ($null -ne $Classes) {

	$Classes | ForEach-Object {
		Add-Content -Path $moduleFile -Value (Get-Content $_.FullName);
	}

}
# Add-PublicFunctions
Add-Content -Path $moduleFile -Value $heading
        # $PublicFunctions;
        $PublicFunctions | ForEach-Object { # Replace the comment block with external help link
            $rawContent = (Get-Content $_.FullName -Raw);
            $commentStartIdx = $rawContent.indexOf('<#');
            if ($commentStartIdx -ge 0) {
                $commentEndIdx = $rawContent.IndexOf('#>');
                $commentLength = $commentEndIdx - ($commentStartIdx-2); #-2 to adjust for the # in front of > and the index starting at 0
                $comment = $rawContent.Substring($commentStartIdx,$commentLength);
                $newComment = "# .ExternalHelp $moduleName-help.xml"
                $Function = $rawContent.Replace($comment,$newComment);
            } else {
                $Function = $rawContent;
            }
            Add-Content -Path $moduleFile -Value $Function
        }
#Add Private Functions
if ($null -ne $PrivateFunctions) {
	$PrivateFunctions | ForEach-Object {
		Add-Content -Path $moduleFile -Value (Get-Content $_.FullName);            
	}
}

$manifest = Join-Path $PSScriptRoot $moduleName "$moduleName.psd1"
$builtManifest = Join-Path $buildPth "$moduleName.psd1";
Copy-Item $manifest $builtManifest;

if (Get-Command Update-PSModuleManifest -ea 0) {
    Update-PSModuleManifest -Path $builtManifest -RootModule "$moduleName.psm1" -FunctionsToExport $PublicFunctions.BaseName
} else {
	"PSResourceGet version of update manifest not found, reverting to psget version, may cause issues with choco nuspec" | out-host;
	Update-ModuleManifest -Path $builtManifest -RootModule "$moduleName.psm1" -FunctionsToExport $PublicFunctions.BaseName
}
Set-EmptyExportArray -psd1Path $builtManifest -ExportType Cmdlets;
Set-EmptyExportArray -psd1Path $builtManifest -ExportType Variables;
