$ErrorActionPreference = 'Stop'

#uninstall just this version of the module from system level paths

$toolsDir = Split-Path -parent $MyInvocation.MyCommand.Definition
#include the additional functions for install
Import-Module "$toolsDir\functions.psm1"

$moduleName = $env:chocolateyPackageName 
$moduleVersion = $env:ChocolateyPackageVersion

Remove-Module -Name $moduleName -force -ea 0;
$destinationPath = @()
$destinationPath += Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules\$moduleName\$moduleVersion"
$destinationPath += Join-Path -Path $env:ProgramFiles -ChildPath "PowerShell\Modules\$moduleName\$moduleVersion"
ForEach ($destPath in $destinationPath) {
    if (Test-path $destPath) {
        Write-verbose "Taking ownership of path $($destpath) and setting permissions to ensure clean removal";
        $logDir = "$env:temp\logs"
        if (!(Test-Path $logDir)) {
            mkdir $logDir -ea 0;
        }
        $takeOwn = start-process -FilePath takeown.exe -ArgumentList "/F `"$($destPath)`" /R /A /D Y" -wait -NoNewWindow -PassThru -RedirectStandardOutput "$logDir\takeown-$modulename-paths.log"
        Write-Verbose "Take Ownership result is $($takeOwn | out-string) - $(Get-content "$logDir\takeown-$modulename-paths.log" | out-string)"
        #no need to keep the redirected output log that was output in verbose
        Remove-Item "$logDir\takeown-$modulename-paths.log" -force -Recurse -ea 0;
        try {
            #give full rights to path being deleted to authenticated users
            $perms = Grant-FullRightsToPath -path $destPath -recurseInherit -ea stop -wa 0 -wait -NoOutHost
            Write-Verbose "grant result is $($perms | out-string)"
        } catch {
            $perms = icacls "$($destPath)" /inheritance:e /grant "Authenticated Users:(OI)(CI)(F)" /T /C /Q
            Write-Verbose "Grant-fullrightstopath had an error, icacls native grant result is $($perms | out-string)"
        }
        try {
            if (Test-Path $destpath) {
                Write-Verbose "Attempting removal of version $moduleVersion of $moduleName installed at $($destpath)"
                [gc]::collect()
                [gc]::waitforpendingfinalizers()
                [gc]::collect()
                Remove-Item -Path $destpath -Force -Recurse -EA stop;
            } else {
                "No install for $modulename found at $($destpath)" | out-host;
            }
        } catch {
            Write-Warning "Version of $moduleName at $($destpath) could not be removed, most likely a dll was still loaded, attempting removal of all but dlls"
            
            Get-ChildItem $destpath -Exclude "*.dll" -Recurse | ForEach-Object {
                Remove-Item -path $destpath.FullName -force -ea 0;
            }
        }        
    }
}
