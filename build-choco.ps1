<#PSScriptInfo

.VERSION 1.0.0

.GUID d34797da-2477-4b8d-90c3-2cff4c2766b6

.AUTHOR JJ Fullmer

.COMPANYNAME 

.COPYRIGHT 2024-2024

.TAGS choco chocolatey psresourceget packagemanagement powershellget

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


.PRIVATEDATA


#>
<#

.DESCRIPTION
build choco module to install published powershell module

.PARAMETER buildPth
Specificy a non-default path to where the built module is found

.PARAMETER useLocal
Switch param to create a temp repository to publish the built module to and download the nuspec and psgetxml from the local 
repo and then adjust that xml to point to the psgallery as the publish repository. Default behavior is to download and package based on latest publicly available package in psgallery

#>
[CmdletBinding()]
Param(
	[string]$buildPth,
    [switch]$useLocal
)

Import-Module .\BuildHelpers.psm1

#lowercase name for choco id compatibility
$moduleName = "fogapi"

if([string]::IsNullOrEmpty($buildPth)) {
	$buildPth = ".\_module_build\$moduleName";
}

if ($useLocal) {
    mkdir "$env:temp\modules" -ea 0 | out-null;
    Register-PSResourceRepository -Name temp -Trusted -Uri "$env:temp\modules" -ea 0
    $repo = "temp"
    publish-PSResource -Repository temp -Path $buildPth
} else {
    try {
        Register-PSResourceRepository -PSGallery -Trusted -ea 0 -wa 0
    } catch {
        "PSgallery already registered" | out-host
        Set-PSResourceRepository -Name PSGallery -Trusted
    }
    $repo = "PSGallery"
}
$chocoPth = "$buildPth\choco";
if (Test-Path $chocoPth) {
    Remove-Item $chocoPth -force -Recurse -ea 0;
}
mkdir $chocoPth -ea 0 | out-null;
$manifest = "$buildPth\$moduleName.psd1"
$cur = test-ModuleManifest -Path $manifest;

$version = $cur.version;

"Version to get is $version" | out-host;

#get the psgetxml
"Saving the temp psresource of version $version with the xml included" | out-host
try {
    Save-PSResource -Name FogApi -Repository $repo -Path $chocoPth -Version $version -IncludeXml -TrustRepository -ea stop;
} catch {
    # "in the catch" | out-host;
    Save-PSResource -Name FogApi -Repository $repo -Path $chocoPth -IncludeXml -TrustRepository;
}
#get the nuspec
"Saving the temp psresource of version $version as a nupkg to get the nuspec" | out-host
try {
    Save-PSResource -Name FogApi -Repository $repo -Path $chocoPth -Version $version -AsNupkg -TrustRepository -ea Stop;
} catch {
    Save-PSResource -Name FogApi -Repository $repo -Path $chocoPth -AsNupkg -TrustRepository;
}

#create the tools and files folders for choco pkg
"Creating choco package folders" | out-host;
mkdir "$chocoPth\$moduleName\$version\tools" -ea 0 | out-null;
mkdir "$chocoPth\$moduleName\$version\tools\files" -ea 0 | out-null;
# if (!(Test-Path "$chocoPth\$moduleName\$version\icons")) {
#     mkdir "$chocoPth\$moduleName\$version\icons" -ea 0 | out-null;
#     Copy-Item "$PSScriptRoot\$modulename\icons\favicon.png" "$chocoPth\$moduleName\$version\icons\favicon.png"
# }


#extract the nupkg as a zip and grab the nuspec
"Extracting the nuspec to sepearate folder" | out-host;
rename-item "$chocoPth\$moduleName.$version.nupkg" -NewName "$moduleName.$version.zip" -Force
Expand-Archive "$chocoPth\$moduleName.$version.zip" -DestinationPath "$chocoPth\$moduleName.$version"
Copy-Item "$chocoPth\$moduleName.$version\$moduleName.nuspec" "$chocoPth\$moduleName\$version\$moduleName.nuspec"
"Deleting the temp nuspec extract path" | out-host
Remove-Item "$chocoPth\$moduleName.$version*" -Force -Recurse

#edit the psgetxml file install location for ps5 and ps7 and save those files in the files folders, remove the downloaded psgetxml
"Importing the clixml into an object" | out-host;
$psgetXml = Import-Clixml "$chocoPth\$moduleName\$version\PSGetModuleInfo.xml";
#if not grabbing the remote nuspec, set the remote to the remote repo
if ($useLocal) {
    $psgetXml.Repository = "PSGallery"
    $psgetXml.RepositorySourceLocation = "https://www.powershellgallery.com/api/v2"
}

#set the ps5 install location and export
# $psgetXml.InstalledLocation = "C:\Program Files\WindowsPowerShell\Modules\$moduleName\$version"
# $psgetXml | Export-Clixml -path "$chocoPth\$moduleName\$version\tools\files\PSGetModuleInfo-ps5.xml"

#set the ps7 install location and export
"Setting the default installedlocation to pwsh 7 install path" | out-host;
$psgetXml.InstalledLocation = "C:\Program Files\PowerShell\Modules\$moduleName\$version"
$psgetXml | Export-Clixml -path "$chocoPth\$moduleName\$version\PSGetModuleInfo.xml" -Force;

$sourcePath = New-Object -TypeName 'System.Collections.generic.list[System.Object]';
Get-ChildItem "$chocoPth\$moduleName\$version" -Exclude ".chocolateyPending","*.nuspec","*.nupkg","tools","icons" | ForEach-Object {
    $src = $_.fullname;
    if ((Test-Path $src) -AND ($src -ne "$chocoPth\$moduleName\$version")) {
        $sourcePath.add(($src))
    }
}

Compress-Archive -Path $sourcePath -DestinationPath "$chocoPth\$modulename\$version\$moduleName.$version.IncludeXml.zip"
$checksum = (Get-filehash "$chocoPth\$modulename\$version\$moduleName.$version.IncludeXml.zip" -Algorithm SHA256).Hash
# Move-Item "$chocoPth\$moduleName\$version\tools\files\$moduleName.$version.IncludeXml.zip" "$chocopth\$moduleName.$version.IncludeXml.zip"
# Remove-Item -Path $sourcePath -Force -ea 0 -Recurse;
# $sourcepath | ForEach-Object {
#     Remove-item
# }
# remove-item "$chocoPth\$moduleName\$version\PSGetModuleInfo.xml" -force -ea 0;

$chocoTemplateDir = "$PSScriptRoot\chocoTemplate\PSGetModule\tools";
Copy-Item "$chocoTemplateDir\chocolateyInstall.ps1" "$chocoPth\$moduleName\$version\tools\chocolateyInstall.ps1" -Force;
Copy-Item "$chocoTemplateDir\functions.psm1" "$chocoPth\$moduleName\$version\tools\functions.psm1" -Force;
Copy-Item "$chocoTemplateDir\chocolateyUninstall.ps1" "$chocoPth\$moduleName\$version\tools\chocolateyUninstall.ps1" -Force;
Copy-Item "$($buildPth | Split-Path | Split-Path)\LICENSE" "$chocoPth\$moduleName\$version\tools\LICENSE" -Force
$chocoInstall = "$chocoPth\$moduleName\$version\tools\chocolateyInstall.ps1";
# $chocoUninstall = "$chocoPth\$moduleName\$version\tools\chocolateyUninstall.ps1";
Find-Replace -file $chocoInstall -findStr '[[checksum]]' -replaceStr $checksum;
Find-Replace -file $chocoInstall -findStr '[[PackageName]]' -replaceStr $moduleName;
Find-Replace -file $chocoInstall -findStr '[[PackageVersion]]' -replaceStr $version;
# Find-Replace -file $chocoUninstall -findStr '[[PackageName]]' -replaceStr $moduleName;
if (!(Get-command choco.exe)) {
    #taken from https://chocolatey.org/install#individual
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
Set-Location "$chocoPth\$modulename\$version"
$nuspec ="$pwd\$moduleName.nuspec"
"Updating nuspec at $nuspec" | out-host;

$nuspecSnippet = @"
    <docsUrl>https://fogapi.readthedocs.io/en/latest</docsUrl>
    <mailingListUrl>https://forums.fogproject.org/topic/12026/powershell-api-module</mailingListUrl>
    <bugTrackerUrl>https://github.com/darksidemilk/FogApi/issues</bugTrackerUrl>
    <projectSourceUrl>https://github.com/darksidemilk/FogApi</projectSourceUrl>
    <packageSourceUrl>https://github.com/darksidemilk/FogApi/tree/master/chocoTemplate/PSGetModule</packageSourceUrl>
</metadata>
"@
#add summary and lowercase id for choco
$titleSnippet = @"
<id>fogapi</id>
    <title>FogApi Powershell Module</title>
    <summary>Powershell Module for using the FOG Project API to simplify imaging and provisioning automations</summary>
"@
$softwareSite = "<projectUrl>https://FOGProject.org</projectUrl>"

$filesSnippet = @"
</metadata>
<files>
    <!-- this section controls what actually gets packaged into the Chocolatey package -->
    <!-- make sure that all files used in the module are included-->
    <file src="tools\**" target="tools" />
</files>
"@

$xmlSpecStr = @"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2011/08/nuspec.xsd">
"@

$xmlSpecSnippet = @"
<?xml version="1.0" encoding="utf-8"?>
<!-- Read this before creating packages: https://chocolatey.org/docs/create-packages -->
<!-- It is especially important to read the above link to understand additional requirements when publishing packages to the community feed aka dot org (https://chocolatey.org/packages). -->
<!-- Test your packages in a test environment: https://github.com/chocolatey/chocolatey-test-environment -->
<!--
This is a nuspec. It mostly adheres to https://docs.nuget.org/create/Nuspec-Reference. Chocolatey uses a special version of NuGet.Core that allows us to do more than was initially possible. As such there are certain things to be aware of:

* the package xmlns schema url may cause issues with nuget.exe
* Any of the following elements can ONLY be used by choco tools - projectSourceUrl, docsUrl, mailingListUrl, bugTrackerUrl, packageSourceUrl, provides, conflicts, replaces 
* nuget.exe can still install packages with those elements but they are ignored. Any authoring tools or commands will error on those elements 
-->
<!-- You can embed software files directly into packages, as long as you are not bound by distribution rights. -->
<!-- * If you are an organization making private packages, you probably have no issues here -->
<!-- * If you are releasing to the community feed, you need to consider distribution rights. -->
<!-- Do not remove this test for UTF-8: if “Ω” doesn’t appear as greek uppercase omega letter enclosed in quotation marks, you should use an editor that supports UTF-8, not this one. -->
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
"@
Set-Content -Path $nuspec -Value (Get-Content $nuspec).Replace("</metadata>",$nuspecSnippet) -Force;
Set-Content -Path $nuspec -Value (Get-Content $nuspec).Replace("<id>FogApi</id>",$titleSnippet) -Force;
Set-Content -Path $nuspec -Value (Get-Content $nuspec).Replace("<owners>FOG Project</owners>","<owners>JJ Fullmer</owners>") -Force;
Set-Content -Path $nuspec -Value (Get-Content $nuspec).Replace("<projectUrl>https://github.com/darksidemilk/FogApi</projectUrl>",$softwareSite) -Force;
Set-Content -Path $nuspec -Value (Get-Content $nuspec).Replace("</metadata>",$filesSnippet) -Force;
Set-Content -Path $nuspec -Value (Get-Content $nuspec).Replace($xmlSpecStr,$xmlSpecSnippet) -Force;

if ($useLocal) {
    Unregister-PSResourceRepository -name temp -ea 0;
    remove-item $env:temp\modules -force -Recurse -ea 0;
}
#fix description and release notes
$chocoPkgSnippet = @"
# FogApi Powershell Module Chocolatey Package

Requires Powershell 5.1+ (Core 7+ recommended).

This package installs the FogApi module in the AllUsers/System scope for:

  - Powershell 7+ (C:\Program Files\Powershell\Modules\FogApi{version})
  - Powershell 5.1 (C:\Program Files\WindowsPowershell\Modules\FogApi{version})

This ensures compatibility across pwsh versions (which are both included in Win11), removing any other existing versions to avoid conflicts.
The uninstall script removes the specific package version of the given Chocolatey package.
You can customize this behavior with package parameters, though defaults are recommended.

## Package Parameters

You can set the following parameters to alter the install behavior:

  - /PS7Only: (true/false) - Install/uninstall only for Powershell 7. Defaults to false. Overwrites PS5Only if BOTH are true
  - /PS5Only: (true/false) - Install/uninstall only for Powershell 5. Defaults to false.
  - /NoRemove: (true/false) - (Install only) Do not remove other versions. Defaults to false.
  - /RemoveAll: (true/false) - (Uninstall only) Uninstall all versions. Defaults to false.

Examples:

Install for Pwsh 7 only without removing other versions: ``choco install fogapi --params "'/PS7Only:true /NoRemove:true'"``
Uninstall all versions: ``choco uninstall fogapi --params "'/RemoveAll'"``

"@
$nuspecContent = Get-Content $nuspec;
[xml]$nuspecXml = $nuspecContent;
$nuspecXml.package.metadata.description = "`n$chocoPkgSnippet`n$($nuspecXml.package.metadata.description)"
$nuspecXml.package.metadata.releaseNotes = "`n$($nuspecXml.package.metadata.releaseNotes)"
$nuspecXml.Save($nuspec);

choco pack
