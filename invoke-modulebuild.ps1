
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


$PublicFunctions = Get-ChildItem "$modulePath\Public" -Recurse -Filter '*.ps1' -EA 0;
$Classes = Get-ChildItem "$modulePath\Classes" -Recurse -Filter '*.ps1' -EA 0;
$PrivateFunctions = Get-ChildItem "$modulePath\Private" -Recurse -Filter '*.ps1' -EA 0;
# mkdir "$PSSCriptRoot\ModuleBuild" -EA 0;
$buildPth = ".\_module_build\$moduleName";
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

$manifest = "$PSScriptRoot\$moduleName\$moduleName.psd1"
Copy-Item $manifest "$buildPth\$moduleName.psd1";
Update-ModuleManifest -Path "$buildPth\$moduleName.psd1" -RootModule "$moduleName.psm1" -FunctionsToExport $PublicFunctions.BaseName