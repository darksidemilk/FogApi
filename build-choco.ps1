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


$moduleName = "FogApi"

if([string]::IsNullOrEmpty($buildPth)) {
	$buildPth = ".\_module_build\$moduleName";
}

if ($useLocal) {
    mkdir "$env:temp\modules" -ea 0 | out-null;
    Register-PSResourceRepository -Name temp -Trusted -Uri "$env:temp\modules" -ea 0
    $repo = "temp"
    publish-PSResource -Repository temp -Path $buildPth -vb
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
mkdir $chocoPth -ea 0 | out-null;
$manifest = "$buildPth\$moduleName.psd1"
$cur = test-ModuleManifest -Path $manifest;

$version = $cur.version;

"Version to get is $version" | out-host;

#get the psgetxml
try {
    Save-PSResource -Name FogApi -Repository $repo -Path $chocoPth -Version $version -IncludeXml -TrustRepository -ea stop;
} catch {
    # "in the catch" | out-host;
    Save-PSResource -Name FogApi -Repository $repo -Path $chocoPth -IncludeXml -TrustRepository;
}
#get the nuspec
try {
    Save-PSResource -Name FogApi -Repository $repo -Path $chocoPth -Version $version -AsNupkg -TrustRepository -ea Stop;
} catch {
    Save-PSResource -Name FogApi -Repository $repo -Path $chocoPth -AsNupkg -TrustRepository;
}

#create the tools and files folders for choco pkg
mkdir "$chocoPth\$moduleName\$version\tools" -ea 0 | out-null;
mkdir "$chocoPth\$moduleName\$version\tools\files" -ea 0 | out-null;
if (!(Test-Path "$chocoPth\$moduleName\$version\icons")) {
    mkdir "$chocoPth\$moduleName\$version\icons" -ea 0 | out-null;
    Copy-Item "$PSScriptRoot\$modulename\icons\favicon.png" "$chocoPth\$moduleName\$version\icons\favicon.png"
}


#extract the nupkg as a zip and grab the nuspec
rename-item "$chocoPth\$moduleName.$version.nupkg" -NewName "$moduleName.$version.zip" -Force
Expand-Archive "$chocoPth\$moduleName.$version.zip" -DestinationPath "$chocoPth\$moduleName.$version"
Copy-Item "$chocoPth\$moduleName.$version\$moduleName.nuspec" "$chocoPth\$moduleName\$version\$moduleName.nuspec"

Remove-Item "$chocoPth\$moduleName.$version*" -Force -Recurse

#edit the psgetxml file install location for ps5 and ps7 and save those files in the files folders, remove the downloaded psgetxml

$psgetXml = Import-Clixml "$chocoPth\$moduleName\$version\PSGetModuleInfo.xml";
#if not grabbing the remote nuspec, set the remote to the remote repo
if ($useLocal) {
    $psgetXml.Repository = "PSGallery"
    $psgetXml.RepositorySourceLocation = "https://www.powershellgallery.com/api/v2"
}

#set the ps5 install location and export
$psgetXml.InstalledLocation = "C:\Program Files\WindowsPowerShell\Modules\$moduleName\$version"
$psgetXml | Export-Clixml -path "$chocoPth\$moduleName\$version\tools\files\PSGetModuleInfo-ps5.xml"

#set the ps7 install location and export
$psgetXml.InstalledLocation = "C:\Program Files\PowerShell\Modules\$moduleName\$version"
$psgetXml | Export-Clixml -path "$chocoPth\$moduleName\$version\tools\files\PSGetModuleInfo-ps7.xml"

remove-item "$chocoPth\$moduleName\$version\PSGetModuleInfo.xml" -force -ea 0;

$chocoTemplateDir = '.\chocoTemplate\PSGetModule\tools';
Copy-Item "$chocoTemplateDir\chocolateyInstall.ps1" "$chocoPth\$moduleName\$version\tools\chocolateyInstall.ps1" -Force;
Copy-Item "$chocoTemplateDir\functions.psm1" "$chocoPth\$moduleName\$version\tools\functions.psm1" -Force;
Copy-Item "$chocoTemplateDir\chocolateyUninstall.ps1" "$chocoPth\$moduleName\$version\tools\chocolateyUninstall.ps1" -Force;
$chocoInstall = "$chocoPth\$moduleName\$version\tools\chocolateyInstall.ps1";
$chocoUninstall = "$chocoPth\$moduleName\$version\tools\chocolateyUninstall.ps1";
Find-Replace -file $chocoInstall -findStr '[[PackageName]]' -replaceStr $moduleName;
Find-Replace -file $chocoInstall -findStr '[[PackageVersion]]' -replaceStr $version;
Find-Replace -file $chocoUninstall -findStr '[[PackageName]]' -replaceStr $moduleName;
if (!(Get-command choco.exe)) {
    #taken from https://chocolatey.org/install#individual
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
Set-Location "$chocoPth\$modulename\$version"
"Updating nuspec" | out-host;
$nuspec ="$pwd\$moduleName.nuspec"

$nuspecSnippet = @"
  <docsUrl>https://fogapi.readthedocs.io/en/latest</docsUrl>
    <mailingListUrl>https://forums.fogproject.org/topic/12026/powershell-api-module</mailingListUrl>
    <bugTrackerUrl>https://github.com/darksidemilk/FogApi/issues</bugTrackerUrl>
    <projectSourceUrl>https://github.com/darksidemilk/FogApi/tree/master/chocoTemplate/PSGetModule</projectSourceUrl>
</metadata>
"@
$titleSnippet = @"
<id>FogApi</id>
    <title>FogApi Powershell Module</title>
    <summary>Powershell Module for using the FOG Project API to simplify imaging and provisioning automations</summary>
"@
# $softwareSite = "<projectUrl>https://FOGProject.org</projectUrl>"

$filesSnippet = @"
</metadata>
<files>
    <!-- this section controls what actually gets packaged into the Chocolatey package -->
    <!-- make sure that all files used in the module are included-->
    <file src="tools\**" target="tools" />
    <!-- <file src="icons\**" target="icons" /> -->
    <file src="en-us\**" target="en-us" />
    <file src="lib\**" target="lib" />
    <!-- <file src="bin\**" target="bin" /> -->
    <file src=".\$moduleName.psd1" target=".\$moduleName.psd1" />
    <file src=".\$moduleName.psm1" target=".\$moduleName.psm1" />
    <!-- <file src="..\..\_module_build\$moduleName.psm1" target=".\$moduleName.psm1" /> -->
    <!-- <file src="..\..\_module_build\$moduleName.psd1" target=".\$moduleName.psd1" /> -->
</files>
"@

Set-Content -Path $nuspec -Value (Get-Content $nuspec).Replace("</metadata>",$nuspecSnippet) -Force;
Set-Content -Path $nuspec -Value (Get-Content $nuspec).Replace("<id>FogApi</id>",$titleSnippet) -Force;
# Set-Content -Path $nuspec -Value (Get-Content $nuspec).Replace("<projectUrl>https://github.com/darksidemilk/FogApi</projectUrl>",$softwareSite) -Force;
Set-Content -Path $nuspec -Value (Get-Content $nuspec).Replace("</metadata>",$filesSnippet) -Force;

if ($useLocal) {
    Unregister-PSResourceRepository -name temp -ea 0;
    remove-item $env:temp\modules -force -Recurse -ea 0;
}
#fix description and release notes
$nuspecContent = Get-Content $nuspec;
[xml]$nuspecXml = $nuspecContent;
$nuspecXml.package.metadata.description = "`n$($nuspecXml.package.metadata.description)"
$nuspecXml.package.metadata.releaseNotes = "`n$($nuspecXml.package.metadata.releaseNotes)"
$nuspecXml.Save($nuspec);


choco pack
