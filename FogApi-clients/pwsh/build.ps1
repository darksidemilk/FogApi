
<#PSScriptInfo

.VERSION 3.0.0

.GUID 473e8205-f9ee-4185-9daa-096fb36cf0b6

.AUTHOR JJ Fullmer

.COMPANYNAME FogProject

.COPYRIGHT 2019-2024

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

		3.0.0
			Updated to be compatible with github actions automated build and release flow
			Added BuildHelpers.psm1 adhoc module functions

		2.0.0.0
			Updated with documentation integrations

		1.0.0.0
			Updated script to proper format

.PRIVATEDATA

#>

#Requires -Modules PlatyPS

<# 

.DESCRIPTION 
 Script to manually build the module, this will install the third party platyps module 
 This simply creates docs from 

 .PARAMETER releaseNote
 A string explaining what was done in the build to be added to the release notes

 .PARAMETER major
 Switch to indicate a major version change is required

 .PARAMETER buildMkdocs
 switch param to install python and requirements and create a local version of the documentation site that will show on read the docs.

 .PARAMETER buildPth
 Provide an explicit path to create the built module in, defaults to creating a _module_build folder in the current directory that is ignored by .gitignore

 .PARAMETER noMkdocsPause
 When buildmkdocs switch is present, the default behavior will be to pause before the build takes place to inform the user how to close the local server. This pause can be bypassed with this switch

 .PARAMETER NoVerStep
 Switch to build without incrementing the version or adding to the release notes, can be used for testing full builds locally and allowing the github actions release workflow handle version increments.

#> 

[CmdletBinding()]
Param(
	[string]$releaseNote,
	[string]$buildPth,
	[switch]$major,
	[switch]$buildMkdocs,
	[switch]$noMkdocsPause,
	[switch]$NoVerStep
)


Import-Module (Join-Path $PSScriptRoot 'BuildHelpers.psm1')

# This script lives in FogApi-clients/pwsh/ but the hand-written module source
# and the docs are still at the repo root, two levels up. Resolved from
# $PSScriptRoot rather than the working directory so the script can be invoked
# from anywhere -- `.\BuildHelpers.psm1` above only worked when the caller
# happened to be sitting in the script's own directory.
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$moduleName = 'FogApi'
$modulePath = "$repoRoot\$moduleName";
if([string]::IsNullOrEmpty($releaseNote)) {
	$releaseNote = (git log -1 --pretty=%B)
}
# Strip co-author/session trailers (and redact any stray email) - these break Chocolatey moderation
# and have no place in a public-facing release note or nuspec.
$releaseNote = ($releaseNote -split "`r?`n" | Where-Object {
	$_ -notmatch '^\s*Co-authored-by:' -and $_ -notmatch '^\s*Claude-Session:' -and $_.Trim() -ne '---------'
}) -join "`n"
$releaseNote = $releaseNote -replace '[\w\.\-\+]+@[\w\.\-]+\.\w+', '' -replace '(\r?\n){3,}', "`n`n"
$releaseNote = $releaseNote.Trim()
if([string]::IsNullOrEmpty($buildPth)) {
	# Repo root, not the working directory. build-choco.ps1 finds LICENSE by
	# walking two levels up from this path, so where it lands is load-bearing
	# and must not depend on where the caller happened to be standing.
	$buildPth = "$repoRoot\_module_build\$moduleName";
}

# New-Item, not mkdir - powershell only defines mkdir as a function on windows; on linux
# and mac it is /usr/bin/mkdir and '-EA 0' is passed through as '-E -A 0'
New-Item -ItemType Directory -Force -Path $modulePath -EA 0 | Out-Null;
# mkdir "$modulePath\tools" -EA 0;
# mkdir "$modulePath\docs" -EA 0;
New-Item -ItemType Directory -Force -Path (Join-Path $modulePath 'lib') -EA 0 | Out-Null;
New-Item -ItemType Directory -Force -Path (Join-Path $modulePath 'bin') -EA 0 | Out-Null;
New-Item -ItemType Directory -Force -Path (Join-Path $modulePath 'Public') -EA 0 | Out-Null;
New-Item -ItemType Directory -Force -Path (Join-Path $modulePath 'Private') -EA 0 | Out-Null;
New-Item -ItemType Directory -Force -Path (Join-Path $modulePath 'Classes') -EA 0 | Out-Null;
New-Item -ItemType Directory -Force -Path (Join-Path $modulePath 'icons') -EA 0 | Out-Null;


#update documentation

# try {
# 	$ses = New-PsSession -EA Stop;
# } catch {
# 	$credential = Get-Credential -Message "input local credentials for new local session"
# 	$ses = New-PsSession -Credential $credential;
# }
$docsPth = "$repoRoot\docs"

# Invoke-Command -Session $ses -ScriptBlock {
	# $moduleName = $Using:moduleName 
	# $modulePath = $Using:modulePath
	# $docsPth = $Using:docsPth 
New-Item -ItemType Directory -Force -Path $docsPth -EA 0 | Out-Null;
Remove-Module $moduleName -force -EA 0;
Import-Module "$modulePath\$moduleName.psm1" -force;
#import any classes so they are recognized and do it twice to resolve classes with dependencies
$classPth = "$modulePath\classes";
$classPth | Get-ChildItem | ForEach-Object { Import-Module $_.Fullname -force -EA 0;}
$classPth | Get-ChildItem | ForEach-Object { Import-Module $_.Fullname -force;}
# Remove old markdown files
"$docsPth\commands" | Get-ChildItem -Filter '*.md' | Remove-Item -Force;
# Remove-Item -Path "$docsPth\ReleaseNotes.md"
New-MarkdownHelp -module $moduleName -Force -OutputFolder "$docsPth\commands";



# Add Online Versions to each commands markdown file
$indexFile = "$docsPth\commands\index.md"
# 	$mkdocsYml = "$PSScriptRoot\mkdocs.yml";
# 	$mkdocs = @"
# site_name: FogApi
# nav:
#   - Home: index.md
#   - About: about_FogApi.md
#   - Release Notes: ReleaseNotes.md
#   - Commands: 
#     - 'Index': 'commands/index.md'
# "@
# 	$mkdocs += "`n";
$index = "# FogAPI`n`n"
Get-ChildItem "$docsPth\commands" | Where-Object name -NotMatch 'index' | Foreach-Object {
	#add online version
	$name = $_.Name;
	$baseName = $_.BaseName
	$file = $_.FullName;
	$link = "https://fogapi.readthedocs.io/en/latest/commands/$basename";
	#insert in onlineVersion at top
	$content = Get-Content $file;
	$onlineStr = ($content | Select-String "online version: *" -Raw).tostring();
	$newOnlineStr = "$onlineStr $link";
	$content = $content.replace($onlineStr,$newOnlineStr);
	try {
		Set-Content -Path $file -Value $content -ea stop;
	} catch {
		"File $file is in use, waiting 2 seconds, running garbage collection, and try again with force" | out-host;
		start-sleep -Seconds 2;
		[gc]::Collect()
		Set-Content -Path $file -Value $content -Force;
	}
	
	#Update commands index
	$index += "## [$basename]($name)`n`n"
	#Update readthedocs nav index
	# $mkdocs += "    - '$basename': 'commands/$name'`n";
	#maybe later add something that converts any functions in .link to related links

}

# $mkdocs += "`ntheme: readthedocs"

# Set-Content $mkdocsYml -value $mkdocs;
Set-Content $indexFile -Value $index;


#build external help xml file for module from md
try {
	New-ExternalHelp -Path $docsPth -OutputPath "$docsPth\en-us" -Force;
	New-ExternalHelp -Path "$docsPth\commands" -OutputPath "$docsPth\en-us" -Force;
} catch {
	Write-Warning "There was an error creating the external help from the markdown. $($error) Removing current external help and trying again"
	Remove-Item -Force -Recurse "$docsPth\en-us";
	New-Item -ItemType Directory -Force -Path (Join-Path $docsPth 'en-us') | Out-Null;
	New-ExternalHelp -Path $docsPth -OutputPath "$docsPth\en-us" -EA 0 -Force;
	New-ExternalHelp -Path "$docsPth\commands" -OutputPath "$docsPth\en-us" -Force;
}

$PublicFunctions = Get-ChildItem "$modulePath\Public" -Recurse -Filter '*.ps1' -EA 0;
$Classes = Get-ChildItem "$modulePath\Classes" -Recurse -Filter '*.ps1' -EA 0;
$PrivateFunctions = Get-ChildItem "$modulePath\Private" -Recurse -Filter '*.ps1' -EA 0;
$aliases = Get-AliasesToExport -psm1Path "$modulePath\$moduleName.psm1" -modulePath $modulePath;

# mkdir "$PSSCriptRoot\ModuleBuild" -EA 0;
# $buildPth = "$env:userprofile\ModuleBuild\$moduleName";

"Creating new module build folder" | out-host;
# Create the build output folder
if (Test-Path $buildPth) {
	Remove-Item $buildPth -force -recurse;
}
New-Item -ItemType Directory -Force -Path $buildPth | Out-Null;

"Copying xml docs to build path" | out-host;
Copy-Item "$docsPth\en-us" "$buildPth\en-us" -Recurse -Exclude '*.md';

"Copying icons folder" | out-host;
Copy-item "$modulePath\icons" "$buildPth\icons" -Recurse -force -ea 0;

"Building module file" | out-host;

$moduleFile = "$buildPth\$moduleName.psm1";
New-Item $moduleFile -Force | Out-Null;


"Adding module file header" | out-host;
Add-Content -Path $moduleFile -Value "`$PSModuleRoot = `$PSScriptRoot";
if ((Get-ChildItem "$modulePath\lib").count -gt 0) {
	Copy-Item "$modulePath\lib" "$buildPth\lib" -Recurse;
	Add-Content -Path $moduleFile -Value "`$script:lib = `"`$PSModuleRoot\lib`"";
}
if ((Get-ChildItem "$modulePath\bin").count -gt 0) {
	Copy-Item "$modulePath\bin" "$buildPth\bin" -Recurse;
	Add-Content -Path $moduleFile -Value "`$script:bin = `"`$PSModuleRoot\bin`"";
}
# Copy-Item "$modulePath\tools" "$buildPth\tools" -Recurse;
Add-Content -Path $moduleFile -Value "`$script:tools = `"`$PSModuleRoot\tools`"";


#Build the psm1 file

#Add Classes
if ($null -ne $Classes) {
	"Adding classes to module file" | out-host;
	$Classes | ForEach-Object {
		Add-Content -Path $moduleFile -Value (Get-Content $_.FullName);
	}
}
# Add-PublicFunctions
# Add-Content -Path $moduleFile -Value $heading
# $PublicFunctions;
"Adding public functions to module file" | Out-Host;
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
"Adding private functions to module file" | Out-Host;
if ($null -ne $PrivateFunctions) {
	$PrivateFunctions | ForEach-Object {
		Add-Content -Path $moduleFile -Value (Get-Content $_.FullName);            
	}
}

#Update The Manifest
"Updating the module manifest" 
$manifest = "$repoRoot\$moduleName\$moduleName.psd1"
$cur = test-ModuleManifest -Path $manifest;

[System.Version]$oldVer = $cur.Version
$verArgs = New-Object System.Collections.Generic.list[system.object];
$MajorStr = (get-date -Format "yyMM")
$verArgs.Add($MajorStr)
if ($major) {
	$verArgs.Add($oldVer.Minor +1)
	$verArgs.Add("0")
} else {
	$verArgs.Add($oldVer.Minor)
	$verArgs.Add($oldVer.Build + 1)
}
# $verArgs.Add(($oldVer.Revision + 1))
# if($verArgs[-1] -eq 0) {$verArgs[-1] += 1}
$newVer = New-Object version -ArgumentList $verArgs;
$releaseNotes = "`n# $newVer`n`n`t$releaseNote`n`nFull change log history available at https://fogapi.readthedocs.io/en/latest/ReleaseNotes/"


$copyRight = (get-date -Format yyyy).tostring()
if ($cur.Copyright -notlike "*-$copyRight") {
	$NewCopyRight = $cur.Copyright -replace("-(.*)","-$copyright")
} else {
	$NewCopyRight = $cur.Copyright;
}

$manifestSplat = @{
	Path = $manifest;
	ReleaseNotes = $releaseNotes;
	ModuleVersion = $newver;
	RootModule = "$moduleName.psm1";
	FunctionsToExport = ($PublicFunctions.BaseName)
	AliasesToExport = $aliases;
	Copyright = $NewCopyRight
}

if ($NoVerStep) {
	"no verstep specified, new version would have been $($newver | out-string) keeping $($cur.Version)" | out-host;
	"not updating release note either, release note would have been $($releaseNotes | Out-String)" | out-host;
	$manifestSplat.Remove('ModuleVersion');
	$manifestSplat.Remove('ReleaseNotes');
}

if($null -eq $aliases) {
	$manifestSplat.Remove('AliasesToExport')
}

# Update-ModuleManifest -Path $manifest -ReleaseNotes $releaseNotes -ModuleVersion $newVer -RootModule "$moduleName.psm1" -FunctionsToExport $PublicFunctions.BaseName
if (Get-Command Update-PSModuleManifest) {
	Update-PSModuleManifest @manifestSplat;
} else {
	"PSResourceGet version of update manifest not found, reverting to psget version, may cause issues with choco nuspec" | out-host; 
	Update-ModuleManifest @manifestSplat;
}

Set-EmptyExportArray -psd1Path $Manifest -ExportType Cmdlets;
Set-EmptyExportArray -psd1Path $Manifest -ExportType Variables;

"Adding manifest to build path" | out-host;

Copy-Item $manifest "$buildPth\$moduleName.psd1";

"updating release notes..." | out-host;
#create release notes markdown
#grab the current release notes
$curnotes = Get-Content "$docsPth\ReleaseNotes.md" -raw;
#create the 'major' version heading string
$heading = "# Release Notes";
$curnotes = $curnotes.Replace($heading,"")
$curnotes = $curnotes.Remove(0,2);
$majorVerStr = "`## $($newVer.Minor).x"
if ($major) {
	"New major version, don't remove old major ver heading. CurNotes is now:`n$curnotes" | out-host
	# pause;
	# $curnotes = $curnotes;

} else {
	"deleting old major ver string to be able to re-add $majorVerStr" | out-host
	$curnotes = $curnotes.Replace($majorVerStr,"");
	$curnotes = $curnotes.Remove(0,2);
}
# $curnotes = $curnotes.TrimStart("`n").TrimStart("`n");
$newContent = $heading
$newContent += "`n`n"
$newContent += $majorVerStr
$newContent += "`n`n"
$newContent += "### $newVer`n`n`t$releaseNote`nsee https://fogapi.readthedocs.io/en/latest/ReleaseNotes/ for full historical change log"
# pause;
if ($NoVerStep) {
	"Not updating release notes markdown because noverstep specified! would have added $($newContent | out-string)" | out-host;
} else {
	$newContent += $curNotes
	Set-Content -Path "$docsPth\ReleaseNotes.md" -value $newContent
}


if ($buildMkdocs) {
	Install-Requirements
	Write-Host "After you hit any key to continue, mkdocs will build from your local repo, local mkdocs temp site url will open in default browser and then the local mkdocs server will be started, it will take a moment to show in the browser, hit ctrl+C in this window to close out the local mkdocs test server" -BackgroundColor Yellow
	if (!$noMkdocsPause) {
		pause;
	}
	Start-MkDocsBuild
}

return $buildPth;