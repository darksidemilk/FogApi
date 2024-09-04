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

function Get-Python {
    [CmdletBinding()]
    param (
        
    )
    
    process {
        "Ensuring Python is installed...." | out-host;

        if (!(Get-Command "python.exe" -ea 0)) {
            Write-Warning "Python not detected in path! Attempting to install with chocolatey package manager"
            Write-Warning "May we install/use chocolatey package manager and install python? This will require admin rights in an elevated shell and the package will handle updating path variables"
            $installCHoco = Read-Host -Prompt "Install choco and python with choco? (Y/N)"
            if ($installCHoco -eq "Y") {
                if (!(Get-Command 'choco' -ea 0)) {
                    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                }
                choco upgrade python -y --no-progress;
                Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1;
                Update-SessionEnvironment
            } else {
                Write-Warning "Python not detected in path! Attempting to Install with winget via msstore or winget version and adding to the path"
                if (Get-Command "winget" -ea 0) {
                    try {
                        winget.exe install "Python 3.11" -s msstore
                    }  catch {
                        "There was an error with winget install, trying winget source" | Out-Host
                        winget.exe install "Python 3.11" -s winget
                    }
                } else {
                    Write-Error "Please manually install python and add it to the environment path then re-run this build/make script";
                    pause;
                    exit;
                }
            }	
            #python should now be installed, make sure it is in $ENV:PATH as well as the script subdir for putting mkdocs in the path
            if (!(Get-Command "python.exe" -ea 0)) {
                "searching for python.exe..."
                $pythonPth = (Get-ChildItem -Filter "python.exe" -Recurse -file -Path "\" -force -ea 0).FullName
                if ($null -ne $pythonPth.count) {
                    if ($pythonPth.count -gt 1) {
                        $pythonPath = $pythonPth | Where-Object {
                            Test-path ("$(Split-Path $($_) -Parent)\Scripts")
                        }
                        $pythonPth = $pythonPath[0];
                    }
                }
                "python found at $($pythonPth), adding parent folder to path, and scripts folder to path" | out-host;
                $ENV:PATH += ";$(Split-Path $($pythonPth[0]) -Parent)"
                $ENV:PATH += ";$(Split-Path $($pythonPth[0]) -Parent)\Scripts"
                Update-SessionEnvVariables;
            }
        }
        
    }
    
}

function Install-Requirements {
	[CmdletBinding()]
    param (
		$requirements = ".\docs\requirements.txt"
	)
    
    process {
        Get-Python;
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

function Grant-FullRightsToPath {
    <#
    .SYNOPSIS
    Use icacls to grant full rights to a user or users of a given path or paths
    
    .DESCRIPTION
    Loops through given paths and users and grants full access to the given paths for the given users
    uses icacls $path /grant username:F /T /C for explicit permissions, or uses inhertiable permissions on parent with -inherit
    You should send all paths without trailing slashes, but if you forget, the trailing slash will be removed for you.
    Unless you specify the -wait switch, the icacls processes will all start in the background. If you specify -wait each process will wait before the next is started
    The -wait or -waitoutput switch will display a string of all the output at the end of the function, a list object of the generated logs with the results is always returned.
    The result logs are stored in C:\logs\perms and have a syntax of the path(with - instead of \)_userOrGroup.log
    i.e. if one of your paths
    
    .PARAMETER path
    The path, or list of paths, to set permissions on
    
    .PARAMETER user
    The user/group or list of users/groups to give full permission to the given paths
    Defaults to Authenticated Users group. If it is a domain user or group, it needs "DOMAIN\common name" syntax
    Usernames and groups can have spaces if they are enclosed in ""

    .PARAMETER inherit
    Switch param to enable inheritance, when specified it will only enable the inheritable permissions on the parent folder
    If not specified, it will set the permissions explicitly on each file.
    IF you also enabled -recurseInherit then the recurse behavior overrides the only setting on the parent folder behavior
    
    .PARAMETER recurseInherit
    Switch param to enable inheritance, when specified it will enable inheritable permissions on the parent folder and all subfolders and files.
    This is typically not neccesarry over normal inherit but is provided as an option for flexibility
    This switch can be enabled with or without the -inherit switch

    .PARAMETER wait
    switch to enable waiting for each icacls process to finish before starting the next. When this is enabled, a string output of the logs will be displayed at the end

    .PARAMETER waitOutput
    Switch to enable a wait at the end of the function for all running icacls to finish, and then generate and display a string output

    .NOTES
    This is a simple wrapper for a common use of icacls. This is the help info for icacls:    
    ICACLS name /save aclfile [/T] [/C] [/L] [/Q]
        stores the DACLs for the files and folders that match the name
        into aclfile for later use with /restore. Note that SACLs,
        owner, or integrity labels are not saved.

    ICACLS directory [/substitute SidOld SidNew [...]] /restore aclfile
                    [/C] [/L] [/Q]
        applies the stored DACLs to files in directory.

    ICACLS name /setowner user [/T] [/C] [/L] [/Q]
        changes the owner of all matching names. This option does not
        force a change of ownership; use the takeown.exe utility for
        that purpose.

    ICACLS name /findsid Sid [/T] [/C] [/L] [/Q]
        finds all matching names that contain an ACL
        explicitly mentioning Sid.

    ICACLS name /verify [/T] [/C] [/L] [/Q]
        finds all files whose ACL is not in canonical form or whose
        lengths are inconsistent with ACE counts.

    ICACLS name /reset [/T] [/C] [/L] [/Q]
        replaces ACLs with default inherited ACLs for all matching files.

    ICACLS name [/grant[:r] Sid:perm[...]]
          [/deny Sid:perm [...]]
          [/remove[:g|:d]] Sid[...]] [/T] [/C] [/L] [/Q]
          [/setintegritylevel Level:policy[...]]

        /grant[:r] Sid:perm grants the specified user access rights. With :r,
            the permissions replace any previously granted explicit permissions.
            Without :r, the permissions are added to any previously granted
            explicit permissions.

        /deny Sid:perm explicitly denies the specified user access rights.
            An explicit deny ACE is added for the stated permissions and
            the same permissions in any explicit grant are removed.

        /remove[:[g|d]] Sid removes all occurrences of Sid in the ACL. With
            :g, it removes all occurrences of granted rights to that Sid. With
            :d, it removes all occurrences of denied rights to that Sid.

        /setintegritylevel [(CI)(OI)]Level explicitly adds an integrity
            ACE to all matching files.  The level is to be specified as one
            of:
                L[ow]
                M[edium]
                H[igh]
            Inheritance options for the integrity ACE may precede the level
            and are applied only to directories.

        /inheritance:e|d|r
            e - enables inheritance
            d - disables inheritance and copy the ACEs
            r - remove all inherited ACEs


    Note:
        Sids may be in either numerical or friendly name form. If a numerical
        form is given, affix a * to the start of the SID.

        /T indicates that this operation is performed on all matching
            files/directories below the directories specified in the name.

        /C indicates that this operation will continue on all file errors.
            Error messages will still be displayed.

        /L indicates that this operation is performed on a symbolic link
          itself versus its target.

        /Q indicates that icacls should suppress success messages.

        ICACLS preserves the canonical ordering of ACE entries:
                Explicit denials
                Explicit grants
                Inherited denials
                Inherited grants

        perm is a permission mask and can be specified in one of two forms:
            a sequence of simple rights:
                    N - no access
                    F - full access
                    M - modify access
                    RX - read and execute access
                    R - read-only access
                    W - write-only access
                    D - delete access
            a comma-separated list in parentheses of specific rights:
                    DE - delete
                    RC - read control
                    WDAC - write DAC
                    WO - write owner
                    S - synchronize
                    AS - access system security
                    MA - maximum allowed
                    GR - generic read
                    GW - generic write
                    GE - generic execute
                    GA - generic all
                    RD - read data/list directory
                    WD - write data/add file
                    AD - append data/add subdirectory
                    REA - read extended attributes
                    WEA - write extended attributes
                    X - execute/traverse
                    DC - delete child
                    RA - read attributes
                    WA - write attributes
            inheritance rights may precede either form and are applied
            only to directories:
                    (OI) - object inherit
                    (CI) - container inherit
                    (IO) - inherit only
                    (NP) - don't propagate inherit
                    (I) - permission inherited from parent container

    Examples:

            icacls c:\windows\* /save AclFile /T
            - Will save the ACLs for all files under c:\windows
              and its subdirectories to AclFile.

            icacls c:\windows\ /restore AclFile
            - Will restore the Acls for every file within
              AclFile that exists in c:\windows and its subdirectories.

            icacls file /grant Administrator:(D,WDAC)
            - Will grant the user Administrator Delete and Write DAC
              permissions to file.

            icacls file /grant *S-1-1-0:(D,WDAC)
            - Will grant the user defined by sid S-1-1-0 Delete and
              Write DAC permissions to file.

    #>
    [CmdletBinding()]
    param (
        [string[]]$path,
        [string[]]$user = (@("Authenticated Users")),
        [switch]$inherit,
        [switch]$wait,
        [switch]$waitOutput,
        [switch]$recurseInherit,
        [switch]$noOutHost
    )
    
    
    process {
      $output = "";
      $prcs = New-List;
      $logs = New-List;
      if (!$noOutHost) {
        "Setting full access permissions for given paths to given users...." | Out-Host;
      } 
      Write-Verbose "Setting full access permissions for given paths:`n$($path)`nto given users`n$($user)`n...."
      $path | ForEach-Object {
          $pth = "$($_)"
          $logBase = "C:\logs\perms"
          New-Dir $logBase | Out-Null;
          if ($pth[-1] -eq '\') {
              if (!$noOutHost) {
                "Removing trailing slash from $pth for parsing" | Out-Host;
              }
              $pth = $pth.TrimEnd("\");
          }
          if (Test-Path $pth) {
            $itm = $pth.replace(":","-").replace("\","-");
            $user | ForEach-Object {
              $curUsr = $_;
              $log = "$logBase\$itm`_$($curUsr.replace("\","-")).log";
              New-Item -ItemType File -path $log -force -ea 0;
              $logs.add($log);
              if ($inherit -or $recurseInherit) {
                if ($recurseInherit) {
                  $argStr = "`"$pth`" /inheritance:e /grant `"$curUsr`:(OI)(CI)(F)`" /T /C /Q"
                } else {
                  $argStr = "`"$pth`" /inheritance:e /grant `"$curUsr`:(OI)(CI)(F)`" /C /Q"
                }
                Write-Verbose "Setting inheritable permissions on $pth for user/group $curUsr`:`n"
              } else {
                $argStr = "`"$pth`" /grant `"$curUsr`:(F)`" /T /C /Q"
                Write-Verbose "Setting explicit permissions on all files in $pth for user/group $curUsr`:`n"
              }
              # "Setting permissions on $pth for user $curUsr" | Out-Host;
              $prc = start-process -FilePath icacls.exe -args $argStr -NoNewWindow -RedirectStandardOutput $log -PassThru -wait:$wait.IsPresent -ea 0;
              $prcs.add($prc)
              Write-Verbose "$($prc | out-string) for $log is started";
              try {
                if ((get-content $log -raw) -match "No mapping between account names and security IDs was done") {
                  throw "user $curUsr is invalid!"
                  return $error[0];
                }
              } catch {
                Write-Verbose "not able to test for user validation"
              }
              
            }
          } else {
            throw "path $pth does not exist!"
            return $error[0];
          }
        }
      if (!$wait -AND $waitOutput) {
        if (!$noOutHost) {
          "waiting on icacls processes to finish...." | Out-Host;
        }
        $prcs | ForEach-Object {
          if ($_.hasexited) {
            Write-Verbose "process is already ended"
          } else {
            try {
              while (!$_.hasexited) {
                start-sleep -milliseconds 10
              }
            } catch {
              Write-Verbose "process is already ended"
            }
          }
        }
      }
      if ($waitOutput -or $wait) {
        if (!$noOutHost) {
          $output = "`nResults of icacls from logs:`n`n"
          $logs | ForEach-Object {
            # $output += "`n______________________________`n"
            $output += $_;
            $output += "`n______________________________`n`n"
            $output += Get-Content $_ -raw;
            $output += "`n------------------------------`n`n`n"
          }
          $output | Out-Host;
        }
      }
      return $logs;
    }
    
}
