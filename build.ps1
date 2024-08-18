
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

 .PARAMETER releaseNote
 A string explaining what was done in the build to be added to the release notes

 .PARAMETER major
 Switch to indicate a major version change is required

 .PARAMETER buildMkdocs
 switch param to install python and requirements and create a local version of the documentation site that will show on read the docs.

#> 

[CmdletBinding()]
Param(
	$releaseNote = "general updates and bug fixes",
	[switch]$major,
	[switch]$buildMkdocs
)

function Install-Requirements {
    [CmdletBinding()]
    param (
        $requirements = ".\docs\requirements.txt"
    )
    
    
    process {
        "Installing Pre-requisites if needed..." | out-host;
        $log = ".\.lastprereqrun"
        $requirementsLastUpdate = (Get-item $requirements).LastWriteTime;
        
        if (Test-Path $log) {
            if ((Get-item $log).LastWriteTime -lt $requirementsLastUpdate) {
                $shouldUpdate = $true;
            } else {
                $shouldUpdate = $false;
            }
        } else {
            $shouldUpdate = $true;
        }

        if ($shouldUpdate) {
            $results = New-Object -TypeName 'System.collections.generic.List[System.Object]';
            $result = & python.exe -m pip install --upgrade pip
            $results.add(($result))
            Get-Content $requirements | Where-Object { $_ -notmatch "#"} | ForEach-Object {
                $result = pip install $_;
                $results.add(($result))
            }
            New-Item $log -ItemType File -force -Value "requirements last installed with pip on $(Get-date)`n`n$($results | out-string)";
        } else {
            "Requirements already up to date" | out-host;
        }
        return (Get-Content $log)
    }
    
}

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
		Set-Content -Path $file -Value $content;
		
		#Update commands index
		$index += "## [$basename]($name)`n`n"
		#Update readthedocs nav index
		# $mkdocs += "    - '$basename': 'commands/$name'`n";
		#maybe later add something that converts any functions in .link to related links

	}

	# $mkdocs += "`ntheme: readthedocs"

	# Set-Content $mkdocsYml -value $mkdocs;
	if ($buildMkdocs) {
		Set-Content $indexFile -Value $index;
		Install-Requirements
	}
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
$buildPth = "$env:userprofile\ModuleBuild\$moduleName";
$moduleFile = "$buildPth\$moduleName.psm1";

# Create the build output folder
if (Test-Path $buildPth) {
	Remove-Item $buildPth -force -recurse;
}
mkdir $buildPth | Out-Null;

New-Item $moduleFile -Force | Out-Null;
Copy-Item "$docsPth\en-us" "$buildPth\en-us" -Recurse -Exclude '*.md';
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

#Update The Manifest

$manifest = "$PSScriptRoot\$moduleName\$moduleName.psd1"
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
$releaseNotes = "`n# $newVer`n`n`t$releaseNote"

Update-ModuleManifest -Path $manifest -ReleaseNotes $releaseNotes -ModuleVersion $newVer -RootModule "$moduleName.psm1" -FunctionsToExport $PublicFunctions.BaseName


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
$newContent += "### $newVer`n`n`t$releaseNote`n"
$newContent += $curNotes
# pause;
Set-Content -Path "$docsPth\ReleaseNotes.md" -value $newContent

return $buildPth;