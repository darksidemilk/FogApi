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

    .EXAMPLE
    Grant-FullRightsToPath -path "C:\Program Files\3shape","C:\ProgramData\3Shape","C:\Program Files (x86)\3shape" -user "Authenticated Users","ARROWHEAD\CAD"

    This will give the CAD usergroup as well as the authenticated users group full access to the program files and program data
    for 3shape programs and files on each file explicitly
    
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


	.LINK
	https://kb.arrowheaddental.com/display/PS/Grant-FullRightsToPath
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
