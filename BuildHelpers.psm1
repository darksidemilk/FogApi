function Test-String {
    <#
    .SYNOPSIS
    Returns true if passed in object is a string that is not null, empty, or whitespace
    
    .DESCRIPTION
    Uses built in string functions to test if a given string is null, empty or whitespace
    if it is not any of these things and has valid content, this returns true otherwise false
    
    .PARAMETER str
    String to test
    
    .EXAMPLE
    Test-string "An example"

    Will return true as it is a valid string with content

    .EXAMPLE
    $s = ""; Test-String $s;

    Will return false as this is an empty string.

    .EXAMPLE
    $str = " "; $str | Test-String

    Will return false as this string is just whitespace

    
    .NOTES
    Meant to simplify input validation tests as test-string $param or $value | test-string is easier to type in an if statement than
    doing [string]::isnullorempty($str) along with [string]::isnullorwhitespace($str)

    #>
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline=$true)]
        $str
    )
    
    
    process {
        $valid = $false;
        if ($null -eq $str) {
            $isString = $false;
        } elseif (($str.gettype().name) -eq "String") {
            $isString = $true;
        } else {
            $isString = $false;
        }
        if ($isString) {
            $empty = [string]::IsNullOrEmpty($str)
            $whitespace = [string]::IsNullOrWhiteSpace($str)
        } else {
            $valid = $false;
        }
        
        if (!$empty -and !$whitespace -and $isString) {
            $valid = $True;
        }
        return $valid;
        
    }
    
}

function Set-EmptyExportArray {
	<#
		.SYNOPSIS
		Sets the string in a psd1 file of an export array to be an empty array for best performance
	
		.DESCRIPTION
		When there are none of something to export from a module it should be set to empty
	
		.PARAMETER psd1Path
		The path to the module manifest file
	
		.PARAMETER ExportType
		The type of export being edited, Functions, Aliases, Cmdlets, or Variables
	
		.EXAMPLE
		Set-EmptyExportArray -psd1path $path -ExportType Aliases
	#>
	[CmdletBinding()]
	param (
		$psd1Path,
		[Parameter()]
		[ValidateSet('Functions','Cmdlets','Aliases','Variables','NestedModules')]
		[String]$ExportType
	)
	
	process {
		if ($ExportType -ne "NestedModules") {
			$Pattern = $ExportType+'ToExport';
		} else {
			$Pattern = $ExportType;
		}
		$content = Get-Content $psd1path;
		$replaceStr = $content | Select-String -SimpleMatch -Pattern $Pattern | Select-object -ExpandProperty Line;
		Write-Verbose "Changing '$replaceStr' to '$Pattern = @()'"
		Set-Content -Path ($psd1path.Replace('psm1','psd1')) -Value ($content.Replace($replaceStr,"$Pattern = @()"))
		$replaceStr = $null;
		return "$Pattern = @()";
	}

}
	
function Get-AliasesToExport {
	<#
		.SYNOPSIS
		Gets the function aliases from a psm1 module file
	
		.DESCRIPTION
		Parses the content of a psm1 file finding the strings matching the pattern for declaring an alias
			Goes through each of those and gets the array of aliases in them and adds them to a list
			Converts that list to an array and returns the value.
			If no aliases exist edits the psd1 file to have aliasestoexport = @()
	
		.PARAMETER psm1Path
		The path to the module script file
	
		.PARAMETER loop
		keep this set to false. Internal bool param used for creating loops at key points of this function
		so that it can process the list of functions differently
	
	#>
	[CmdletBinding()]
	param (
		[string]$psm1Path,
		[bool]$loop=$false,
		[string]$modulePath
	)

	process {
		if ($loop -eq $false) {
			if ([string]::IsNullOrEmpty($modulePath)) {
				$modulePath = "$((Get-Item $psm1Path).PSParentPath)";
				if (!(Test-Path $modulePath)) {
					$modulePath = "$((Get-Item $psm1Path).PSParentPath)\$((Get-item $psm1Path).BaseName)";
				}
			}
			$PublicFunctions = Get-ChildItem "$modulePath\Public" -Recurse -Filter '*.ps1' -EA 0;;
			if ($null -ne $PublicFunctions) {
				$aliasList = New-Object System.Collections.Generic.List[string];
				$PublicFunctions | ForEach-Object {
					# $_ | out-host;
					(Get-AliasesToExport -psm1Path $_.FullName -loop $true) | ForEach-Object {
						$aliasList.add($_);
					}
					# $_ | Out-Host;
					# $aliases | Out-host;
				}
				$loop = $true;
				$aliases = $aliasList.ToArray();
			}
			Write-Debug "aliases is $($aliases)";
			Write-Debug "list is $($aliasList)";
		}
		$content = Get-content $psm1path;
		$cmdletBndLines = ($content | Select-String -Pattern "\[CmdletBinding." | Where-Object Line -NotMatch 'Select-String').LineNumber;
		
		# [string[]]$aliasStr = (($content)) | Select-String -SimpleMatch -Pattern "[Alias(" | Where-Object Line -NotMatch 'Select-String').Line;
		if ($null -ne $cmdletBndLines) {
			$aliasList = New-Object System.Collections.Generic.List[string];
			$cmdletBndLines | ForEach-Object {
				# $aliasIndex = ($content.indexof($_)) + 1
				$aliasStr = $content[$_];
				# $aliasStr;
				if (($aliasStr -match "\[Alias\(") -and ($aliasStr -notmatch "#\[Alias\(")) { #don't grab aliases that have been commented out
					$funcAliases = $aliasStr.substring($aliasStr.indexOf("(")).TrimEnd(']').TrimEnd(')').TrimStart('(').Replace("'",'') -split ','
					# $aliasIndex;
					# $funcAliases;
					$funcAliases.ForEach({
						if ((Test-String $_) -and ($_ -notlike "*alias-name*")  ) {
							if ($_ -match "<#") {
								#remove any commented out aliases from split string
								$funcAlias = $_;
								$funcAlias = $funcAlias.remove($funcalias.indexof("<#"),$funcalias.indexof("#>")-$funcalias.indexof("<#")+2)
								if (Test-String $funcAlias) {
									$aliasList.add($funcAlias)
								}
							} else {
								$aliasList.add($_)
							}
						}
					})
				}
			}
			$aliases += $aliasList;
			Write-Debug "Alias List: $($aliasList)";
			Write-Debug "Aliases: $($aliases)"
		} else {
			if ($psm1Path -notmatch '.ps1' -AND $loop -eq $false -AND ($null -eq $PublicFunctions)){
				"here" | Out-Host
				$psm1Path | Out-Host;
				Set-EmptyExportArray -psd1Path (($psm1path.Replace('psm1','psd1'))) -ExportType Aliases
			}
			$aliases += $null;
		}
		return $aliases | Sort-Object -Unique;
	}
}
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

function Start-MkDocsBuild {
    [CmdletBinding()]
    param (
        $SOURCEDIR=".",
	    $BUILDDIR="$SOURCEDIR\docs"
    )
    
    
    process {
        Set-Location $SOURCEDIR
        if (!(Test-Path $BUILDDIR)) {
            mkdir $BUILDDIR;
        }


        try {
            & mkdocs build -d $BUILDDIR | Out-Null
        } catch {
            try {
                $mkDocs = (Get-ChildItem -Filter "mkdocs.exe" -Recurse -file -Path "\" -force -ea 0).FullName;
                if ( !($mkdocs.count -eq 1) ) {
                	Write-Warning "Multiple versions of mkdocs.exe found in system, will try first one $($mkdocs | out-string). "
                
                    $mkDocs = $mkdocs[0]
                } 
                & $mkDocs build -d $BUILDDIR
            } catch {
                "" | Out-Host
                "The 'mkdocs.exe' command was not found. Make sure you have mkdocs installed with pip python package manager and that the path to python scripts is added to your path" | Out-Host
                "This should have been done automatically with the make.ps1 make/build script" | Out-Host
                return "mkdocs not found";
            }
        }
        start "http:\\localhost:8000"
        & mkdocs.exe serve 
        # "$buildDir\index.html"
        return "local dev server version opened in default browser"
        
    }
}