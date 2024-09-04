$ErrorActionPreference = 'Stop'

# $toolsDir = Split-Path -parent $MyInvocation.MyCommand.Definition
$moduleName = '[[PackageName]]'  # this may be different from the package name and different case
# $moduleVersion = '[[PackageVersion]]' #not specifying version

Remove-Module -Name $moduleName -force -ea 0;
$destinationPath = @()
$destinationPath += Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules\$moduleName"
$destinationPath += Join-Path -Path $env:ProgramFiles -ChildPath "PowerShell\Modules\$moduleName"
ForEach ($destPath in $destinationPath) {
    Write-Verbose "Uninstalling any current versions installed at $destPath"
    if (Test-path $destPath) {
        $curVersions = Get-ChildItem $destPath -Directory -ea 0;
        if ($null -ne $curVersions) {
            [gc]::collect();
            $curVersions | Foreach-object { 
                try {
                    Remove-Item -Path $_.FullName -Force -Recurse -EA stop;
                } catch {
                    Write-Warning "Couldn't remove path $($_.fullname) version may be in use, closing any open powershells"
                    Get-Process powershell,pwsh -ea 0 | Stop-process -force -ea 0;
                    [gc]::collect();
                    Remove-Item -Path $_.FullName -Force -Recurse -EA 0;
                }
            }
        }
    }
}