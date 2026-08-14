function Install-FogService {
<#
.SYNOPSIS
Attempts to install the fog service

.DESCRIPTION
Attempts to download and install silently and then not so silently the fog service

.PARAMETER fogServer
the server to download from and connect to

.EXAMPLE
Install-FogService

Will get the fogServer from the fogapi settings and use that servername to download the 
installers and then attempts first a silent install on the msi. And attempts a interactive
install of the smart installer if that fails 

#>

    [CmdletBinding()]
    param (
        $fogServer = ((Get-FogServerSettings).fogServer)
    )

    process {
        if ($script:IsPosix) {
            #the linux fog client is a different artifact installed through the distro's package
            #manager, so there is nothing meaningful for this to do here
            Write-Warning "This installs the windows fog client and is only implemented for windows. On linux install the fog client through your package manager.";
            return $null;
        }
        if ($fogServer -like "http*") {
            $fileUrl = "$fogServer/fog/client/download.php?newclient";
            $fileUrl2 = "$fogServer/fog/client/download.php?smartinstaller";
        } else {
            $fileUrl = "http://$fogServer/fog/client/download.php?newclient";
            $fileUrl2 = "http://$fogServer/fog/client/download.php?smartinstaller";
        }
        Write-Host "Making temp download dir";
        New-Item -ItemType Directory -Force -Path 'C:\fogtemp' | Out-Null;
        Write-Host "downloading installer";
        Invoke-WebRequest -URI $fileUrl -UseBasicParsing -OutFile 'C:\fogtemp\fog.msi';
        Invoke-WebRequest -URI $fileUrl2 -UseBasicParsing -OutFile 'C:\fogtemp\fog.exe';
        "installing fog service" | out-host;
        try {
            "Attempting silent msi install..." | out-host;
            Start-Process -FilePath msiexec -ArgumentList @('/i','C:\fogtemp\fog,msi','/qn') -NoNewWindow -Wait;
        } catch {
            "There was an error, attempting 'smart installer' and sending keystrokes to run through the wizard..." | out-host;
            if ($null -eq (Get-Service FogService -EA 0)) {
                & "C:\fogTemp\fog.exe";
                Write-Host "Waiting 10 seconds then sending 10 enter keys"
                Start-Sleep 10
                $wshell = New-Object -ComObject wscript.shell;
                $wshell.AppActivate('Fog Service Setup')            
                $wshell.SendKeys("{Enter}")
                $wshell.SendKeys("{Space}")
                $wshell.SendKeys("{Enter}")
                $wshell.SendKeys("{Enter}")
                $wshell.SendKeys("{Enter}")
                $wshell.SendKeys("{Enter}")
                Write-Host "waiting 30 seconds for service to install"
                Start-Sleep 30
                Write-host "sending more enter keys"
                $wshell.SendKeys("{Enter}")
                $wshell.SendKeys("{Enter}")
                $wshell.SendKeys("{Enter}")
                $wshell.SendKeys("{Enter}")
                $wshell.SendKeys("{Enter}")
            }
        }
        Write-Host "removing download file and temp folder";
        Remove-Item -Force -Recurse C:\fogtemp;
        Write-Host "Starting fogservice";
        if ($null -ne (Get-Service FogService)) {
            Start-Service FOGService;
        }
        return;
    }

}
