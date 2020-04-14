
<#PSScriptInfo

.VERSION 2.0.0.0

.GUID 473e8205-f9ee-4185-9daa-096fb36cf0b6

.AUTHOR JJ Fullmer

.COMPANYNAME FogProject

.COPYRIGHT 2019

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

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
 This is a light version of the build script I use, but it should be enough for basic testing
 of new features. The original contains propietary code that can't be shared.

#> 
[CmdletBinding()]
Param()

$moduleName = 'FogApi'
$modulePath = "$PSScriptRoot\$moduleName";

mkdir $modulePath -EA 0;
# mkdir "$modulePath\tools" -EA 0;
# mkdir "$modulePath\docs" -EA 0;
mkdir "$modulePath\lib" -EA 0;
mkdir "$modulePath\bin" -EA 0;
mkdir "$modulePath\Public" -EA 0;
mkdir "$modulePath\Private" -EA 0;
mkdir "$modulePath\Classes" -EA 0;

#update documentation

# try {
# 	$ses = New-PsSession -EA Stop;
# } catch {
# 	$credential = Get-Credential -Message "input local credentials for new local session"
# 	$ses = New-PsSession -Credential $credential;
# }
$docsPth = "$PSScriptRoot\docs" 

# Invoke-Command -Session $ses -ScriptBlock {
	# $moduleName = $Using:moduleName 
	# $modulePath = $Using:modulePath
	# $docsPth = $Using:docsPth 
	mkdir $docsPth -EA 0;
	Remove-Module $moduleName -force -EA 0;
	Import-Module "$modulePath\$moduleName.psm1" -force;
	#import any classes so they are recognized and do it twice to resolve classes with dependencies
	$classPth = "$modulePath\classes";
	$classPth | Get-ChildItem | ForEach-Object { Import-Module $_.Fullname -force -EA 0;}
	$classPth | Get-ChildItem | ForEach-Object { Import-Module $_.Fullname -force;}
	# Remove old markdown files
	"$docsPth\commands" | Get-ChildItem -Filter '*.md' | Remove-Item -Force;
	New-MarkdownHelp -module $moduleName -Force -OutputFolder "$docsPth\commands";
	
	
	
	# Add Online Versions to each commands markdown file
	$indexFile = "$docsPth\commands\index.md"
	$mkdocsYml = "$PSScriptRoot\mkdocs.yml";
	$mkdocs = @"
site_name: FogApi
nav:
	- Home: index.md
	- About: about_FogApi.md
	- Commands: 
		- 'Index': 'commands/index.md'
"@
	$mkdocs += "`n";
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
		Set-Content -Path $file -Value $content;
		
		#Update commands index
		$index += "## [$basename]($name)`n`n"
		#Update readthedocs nav index
		$mkdocs += "`t`t- '$basename': 'commands/$name'`n";
		#maybe later add something that converts any functions in .link to related links

	}

	$mkdocs += "`ntheme: readthedocs"

	Set-Content $mkdocsYml -value $mkdocs;
	Set-Content $indexFile -Value $index;

	try {
		New-ExternalHelp -Path $docsPth -OutputPath "$docsPth\en-us" -Force;
		New-ExternalHelp -Path "$docsPth\commands" -OutputPath "$docsPth\en-us" -Force;
	} catch {
		Write-Warning "There was an error creating the external help from the markdown. $($error) Removing current external help and trying again"
		Remove-Item -Force -Recurse "$docsPth\en-us";
		mkdir "$docsPth\en-us"
		New-ExternalHelp -Path $docsPth -OutputPath "$docsPth\en-us" -EA 0 -Force;
		New-ExternalHelp -Path "$docsPth\commands" -OutputPath "$docsPth\en-us" -Force;
	}
# }

# $ses | Remove-PsSession;

$PublicFunctions = Get-ChildItem "$modulePath\Public" -Recurse -Filter '*.ps1' -EA 0;
$Classes = Get-ChildItem "$modulePath\Classes" -Recurse -Filter '*.ps1' -EA 0;
$PrivateFunctions = Get-ChildItem "$modulePath\Private" -Recurse -Filter '*.ps1' -EA 0;
# mkdir "$PSSCriptRoot\ModuleBuild" -EA 0;
$buildPth = "$Home\ModuleBuild\$moduleName";
$moduleFile = "$buildPth\$moduleName.psm1";

# Create the build output folder
if (Test-Path $buildPth) {
	Remove-Item $buildPth -force -recurse;
}
mkdir $buildPth | Out-Null;

New-Item $moduleFile -Force | Out-Null;
Copy-Item "$modulePath\$moduleName.psd1" "$buildPth\$moduleName.psd1";
Copy-Item "$docsPth\en-us" "$buildPth\en-us" -Recurse -Exclude '*.md';
Add-Content -Path $moduleFile -Value "`$PSModuleRoot = `$PSScriptRoot";
if ((Get-ChildItem "$modulePath\lib").count -gt 0) {
	Copy-Item "$modulePath\lib" "$buildPth\lib" -Recurse;
	Add-Content -Path $moduleFile -Value "`$lib = `"`$PSModuleRoot\lib`"";
}
if ((Get-ChildItem "$modulePath\bin").count -gt 0) {
	Copy-Item "$modulePath\bin" "$buildPth\bin" -Recurse;
	Add-Content -Path $moduleFile -Value "`$bin = `"`$PSModuleRoot\bin`"";
}
# Copy-Item "$modulePath\tools" "$buildPth\tools" -Recurse;
Add-Content -Path $moduleFile -Value "`$tools = `"`$PSModuleRoot\tools`"";


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
	$PrivateFunctions | % {
		Add-Content -Path $moduleFile -Value (Get-Content $_.FullName);            
	}
}
