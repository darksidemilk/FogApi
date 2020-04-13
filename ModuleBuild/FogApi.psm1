$PSModuleRoot = $PSScriptRoot
$lib = "$PSModuleRoot\lib"
$tools = "$PSModuleRoot\tools"
function Add-FogHostMac {
# .ExternalHelp FogApi-help.xml
    
    [CmdletBinding()]
    param ( 
        $hostID,
        $macAddress,
        [switch]$primary
    )

    process {
        if ($hostID.gettype().name -ne "Int32"){
            try {
                $hostID = Get-FogHost -hostname $hostID
            } catch {
                Write-Error "Please provide a valid hostid or hostname"
                exit;
            }
        }
        $newMac = @{
            hostID       = "$hostID"
            mac          = $macAddress
            description  = " "
            pending      = 0
            primary      = 0
            clientIgnore = 0
            imageIgnore  = 0
        }
        if ($primary) {
            $newMac.Primary = 1;
        }
        return New-FogObject -type object -coreObject macaddressassociation -jsonData ($newMac | ConvertTo-Json)
    }
    
}

function Approve-FogPendingMac {
# .ExternalHelp FogApi-help.xml
    
    [CmdletBinding()]
    param ( 
        [object]$macObject
    )

    process {
        $macObject.pending = 1;
        return Update-FogObject -type object -coreObject macaddressassociation -IDofObject $macObject.id -jsonData ($macObject | ConvertTo-Json)
    }
    
}

function Deny-FogPendingMac {
# .ExternalHelp FogApi-help.xml
    
    [CmdletBinding()]
    [Alias('Remove-FogMac')]
    param ( 
        $macObject
    )

    process {
        return Remove-FogObject -type object -coreObject macaddressassociation -IDofObject $macObject.id;
    }
    
}

function Get-FogActiveTasks {
    # .ExternalHelp FogApi-help.xml
    
    [CmdletBinding()]
    param ()
    
    process {
        return Get-FogObject -type objectactivetasktype -coreActiveTaskObject task | Select-Object -ExpandProperty tasks        
    }
}
function Get-FogAssociatedSnapins {
# .ExternalHelp FogApi-help.xml
    
    [CmdletBinding()]
    param (
        $hostId=((Get-FogHost).id)
    )
    
    process {
        $AllAssocs = (Invoke-FogApi -Method GET -uriPath snapinassociation).snapinassociations;
        $snapins = New-Object System.Collections.Generic.List[object];
        # $allSnapins = Get-FogSnapins;
        $AllAssocs | Where-Object hostID -eq $hostID | ForEach-Object {
            $snapinID = $_.snapinID;
            $snapins.add((Invoke-FogApi -uriPath "snapin\$snapinID"))
        }
        return $snapins;
    }
    
}
function Get-FogGroup {
# .ExternalHelp FogApi-help.xml
    [CmdletBinding()]
    param (
        [int]$hostId
    )

    begin {
        [bool]$found = $false;
        Write-Verbose 'Getting all fog group associations...';
        $groupAssocs = (Invoke-FogApi -uriPath groupassociation).groupassociations;
        Write-Verbose 'Getting all fog groups...';
        $groups = (Invoke-FogApi -uriPath group).groups;
    }

    process {
        Write-Verbose "Finding group association for hostid of $hostId";
        $hostGroups = $groupAssocs | Where-Object hostID -eq $hostId;
        Write-Verbose "filtering out everyone and touchscreen group";
        $hostGroups = $hostGroups | Where-Object groupID -ne 3; #groupID 3 is the everyone group, don't include that
        $hostGroups = $hostGroups | Where-Object groupID -ne 11; #groupID 11 is the wkstouchscreens group, don't include that either

        Write-Verbose "finding group that matches group id of $hostGroups...";
        $group = $groups | Where-Object id -eq $hostGroups.groupID;
        Write-Verbose 'checking if group was found...';
        if($null -ne $group -AND $group -ne "") { $found = $true; Write-Verbose 'group found!'}
    }

    end {
        if($found){
            return $group;
        }
        return $found;
    }

}

function Get-FogHost {
# .ExternalHelp FogApi-help.xml
    
    [CmdletBinding()]
    param (
        [string]$uuid,
        [string]$hostName,
        [string]$macAddr,
        $hosts = (Get-FogHosts)
    )

    begin {
        [bool]$found = $false;
        Write-Verbose 'Checking for passed variables'
        if (!$uuid -and !$hostName -and !$macAddr) {
            Write-Verbose 'no params given, getting current computer variables';
            $compSys = (Get-WmiObject Win32_ComputerSystemProduct);
            if ($compSys.UUID -notmatch "12345678-9012-3456-7890-abcdefabcdef" ) {
                $uuid = $compSys.UUID;
            } else {
                $uuid = ($compSys.Qualifiers | Where-Object Name -match 'UUID' | Select-Object -ExpandProperty Value);
            }
            $macAddr = ((Get-NetAdapter | Select-Object MacAddress)[0].MacAddress).Replace('-',':');
            $hostName = $(hostname);
        }
        Write-Verbose 'getting all hosts to search...';
        Write-Verbose "search terms: uuid is $uuid, macAddr is $macAddr, hostname is $hostName";
    }

    process {
        Write-Verbose 'finding host in hosts';
        [bool]$found = $false;
        $hostObj = $hosts | Where-Object {
            ($uuid -ne "" -AND $_.inventory.sysuuid -eq $uuid) -OR `
            ($hostName -ne "" -AND $_.name -eq $hostName) -OR `
            ($macAddr -ne "" -AND $_.macs -contains $macAddr);
            if  ($uuid -ne "" -AND $_.inventory.sysuuid -eq $uuid) {
                 Write-Verbose "$($_.inventory.sysuuid) matches the uuid $uuid`! host found";
                 $found = $true;
            }
            if ($macAddr -ne "" -AND $_.macs -contains $macAddr) {
                Write-Verbose "$($_.macs) matches the macaddress $macAddr`! host found";
                $found = $true;
            }
            if  ($hostName -ne "" -AND $_.name -eq $hostName) {
                Write-Verbose "$($_.name) matches the hostname $hostName`! host found";
                $found = $true;
            }
        }
    }

    end {
        if ($found){
            return $hostObj;
        }
        return $found; #return false if host not found
    }

}

function Get-FogHosts {
# .ExternalHelp FogApi-help.xml
    
    [CmdletBinding()]
    param (

    )
    
    begin {
        Write-Verbose "getting fog hosts"
    }
    
    process {
        $hosts = Get-FogObject -type Object -CoreObject host | Select-Object -ExpandProperty hosts
    }
    
    end {
        return $hosts;
    }

}

function Get-FogInventory {
# .ExternalHelp FogApi-help.xml

    [CmdletBinding()]
    param (
        $hostObj = (Get-FogHost)
    )

    begin {
        $comp = Get-WmiObject -Class Win32_ComputerSystem;
        $compSys = Get-WmiObject -Class Win32_ComputerSystemProduct;
        $cpu = Get-WmiObject -Class Win32_processor;
        $bios = Get-WmiObject -Class Win32_Bios;
        $hdd = Get-WmiObject -Class Win32_DiskDrive | Where-Object DeviceID -match '0'; #get just drive 0 in case of multiple drives
        $baseBoard = Get-WmiObject -Class Win32_BaseBoard;
        $case = Get-WmiObject -Class Win32_SystemEnclosure;
        $info = Get-ComputerInfo;
    }

    process {
        $hostObj.inventory.hostID        = $hostObj.id;
        # $hostObj.inventory.primaryUser   =
        # $hostObj.inventory.other1        =
        # $hostObj.inventory.other2        =
        $hostObj.inventory.createdTime   = $((get-date -format u).replace('Z',''));
        # $hostObj.inventory.deleteDate    = '0000-00-00 00:00:00'
        $hostObj.inventory.sysman        = $compSys.Vendor; #manufacturer
        $hostObj.inventory.sysproduct    = $compSys.Name; #model
        $hostObj.inventory.sysversion    = $compSys.Version;
        $hostObj.inventory.sysserial     = $compSys.IdentifyingNumber;
        if ($compSys.UUID -notmatch "12345678-9012-3456-7890-abcdefabcdef" ) {
            $hostObj.inventory.sysuuid       = $compSys.UUID;
        } else {
            $hostObj.inventory.sysuuid       = ($compSys.Qualifiers | Where-Object Name -match 'UUID' | Select-Object -ExpandProperty Value);
        }
        $hostObj.inventory.systype       = $case.chassistype; #device form factor found chassistype member of $case but it references a list that hasn't been updated anywhere I can find. i.e. returns 35 for a minipc but documented list only goes to 24
        $hostObj.inventory.biosversion   = $bios.name;
        $hostObj.inventory.biosvendor    = $bios.Manufacturer;
        $hostObj.inventory.biosdate      = $(get-date $info.BiosReleaseDate -Format d);
        $hostObj.inventory.mbman         = $baseBoard.Manufacturer;
        $hostObj.inventory.mbproductname = $baseBoard.Product;
        $hostObj.inventory.mbversion     = $baseBoard.Version;
        $hostObj.inventory.mbserial      = $baseBoard.SerialNumber;
        $hostObj.inventory.mbasset       = $baseBoard.Tag;
        $hostObj.inventory.cpuman        = $cpu.Manufacturer;
        $hostObj.inventory.cpuversion    = $cpu.Name;
        $hostObj.inventory.cpucurrent    = "Current Speed: $($cpu.currentClockSpeed) MHz";
        $hostObj.inventory.cpumax        = "Max Speed $($cpu.MaxClockSpeed) MHz";
        $hostObj.inventory.mem           = "MemTotal: $($comp.TotalPhysicalMemory) kB";
        $hostObj.inventory.hdmodel       = $hdd.Model;
        $hostObj.inventory.hdserial      = $hdd.SerialNumber;
        $hostObj.inventory.hdfirmware    = $hdd.FirmareRevision;
        $hostObj.inventory.caseman       = $case.Manufacturer;
        $hostObj.inventory.casever       = $case.Version;
        $hostObj.inventory.caseserial    = $case.SerialNumber;
        $hostObj.inventory.caseasset     = $case.SMBIOSAssetTag;
        $hostObj.inventory.memory        = "$([MATH]::Round($(($comp.TotalPhysicalMemory) / 1GB),2)) GiB";
    }

    end {
        $jsonData = $hostObj.inventory | ConvertTo-Json;
        return $jsonData;
    }

}

function Get-FogLog {
# .ExternalHelp FogApi-help.xml

    [CmdletBinding()]
    param (
        [switch]$static
    )
    
    begin {
        $fogLog = 'C:\fog.log';
    }
    
    process {
        if (!$static) {
            "Starting dynamic fog log in new window, Hit Ctrl+C on new window or close it to exit dynamic fog log" | Out-Host;
            Start-Process Powershell.exe -ArgumentList "-Command `"Get-Content $fogLog -Wait`"";
        }
        else {
            Get-Content $fogLog;
        }
    }
    
    end {
        return;
    }

}

function Get-FogObject {
# .ExternalHelp FogApi-help.xml

    [CmdletBinding()]
    param (
        # The type of object being requested
        [Parameter(Position=0)]
        [ValidateSet("objectactivetasktype","object","search")]
        [string]$type,
        # The json data for the body of the request
        [Parameter(Position=2)]
        [Object]$jsonData,
        # The id of the object to get
        [Parameter(Position=3)]
        [string]$IDofObject
    )

    DynamicParam { $paramDict = Set-DynamicParams $type; return $paramDict;}

    begin {
        $paramDict | % { New-Variable -Name $_.Keys -Value $($_.Values.Value);}
        Write-Verbose "Building uri and api call for $($paramDict.keys) $($paramDict.values.value)";
        switch ($type) {
            objectactivetasktype {
                $uri = "$coreActiveTaskObject/current";
            }
            object {
                if ($null -eq $IDofObject -OR $IDofObject -eq "") {
                    $uri = "$coreObject";
                }
                else {
                    $uri = "$coreObject/$IDofObject";
                }
            }
            search {
                $uri = "$type/$stringToSearch";
            }
        }
        Write-Verbose "uri for get is $uri";
        $apiInvoke = @{
            uriPath=$uri;
            Method="GET";
            jsonData=$jsonData;
        }
        if ($null -eq $apiInvoke.jsonData -OR $apiInvoke.jsonData -eq "") {
            $apiInvoke.Remove("jsonData");
        }
    }

    process {
        $result = Invoke-FogApi @apiInvoke;
    }

    end {
        return $result;
    }

}

function Get-FogServerSettings {
# .ExternalHelp FogApi-help.xml

    [CmdletBinding()]
    param ()

    begin {
        Write-Verbose "Pulling settings from settings file"
        $settingsFile = "$ENV:APPDATA\FogApi\api-settings.json"
        if (!(Test-path $settingsFile)) {
            if (!(Test-Path "$ENV:APPDATA\FogApi")) {
                mkdir "$ENV:APPDATA\FogApi";
            }
            Copy-Item "$tools\settings.json" $settingsFile -Force
        }       
    }

    process {
        $serverSettings = (Get-Content $settingsFile | ConvertFrom-Json);
    }

    end {
        return $serverSettings;
    }

}

function Get-FogSnapins {
# .ExternalHelp FogApi-help.xml
    
    [CmdletBinding()]
    param ()
    
    
    process {
        return (Invoke-FogApi -Method GET -uriPath snapin).snapins;
    }
    
    
}
function Get-PendingMacsForHost {
    # .ExternalHelp FogApi-help.xml
    
    [CmdletBinding()]
    param (
        $hostID
    )
    
    
    process {
        if ($hostID.gettype().name -ne "Int32"){
            try {
                $hostID = Get-FogHost -hostname $hostID
            } catch {
                Write-Error "Please provide a valid hostid or hostname"
                exit;
            }
        }
        return Get-FogObject -type object -coreObject macaddressassociation | select-object -ExpandProperty macaddressassociations | Where-Object hostID -match $hostID | Where-Object pending -ne 0;
    }
    
}
function Install-FogService {
# .ExternalHelp FogApi-help.xml

    [CmdletBinding()]
    param (
        $fogServer = ((Get-FogServerSettings).fogServer)
    )
    begin {
        $fileUrl = "http://$fogServer/fog/client/download.php?newclient";
        $fileUrl2 = "http://$fogServer/fog/client/download.php?smartinstaller";
        Write-Host "Making temp download dir";
        mkdir C:\fogtemp;
        Write-Host "downloading installer";
        Invoke-WebRequest -URI $fileUrl -UseBasicParsing -OutFile 'C:\fogtemp\fog.msi';
        Invoke-WebRequest -URI $fileUrl2 -UseBasicParsing -OutFile 'C:\fogtemp\fog.exe';
    }
    process {
        Write-Host "installing fog service";
        try {
            Start-Process -FilePath msiexec -ArgumentList @('/i','C:\fogtemp\fog,msi','/quiet','/qn','/norestart') -NoNewWindow -Wait;
        } catch {
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
    }
    end {
        Write-Host "removing download file and temp folder";
        Remove-Item -Force -Recurse C:\fogtemp;
        Write-Host "Starting fogservice";
        if ($null -ne (Get-Service FogService)) {
            Start-Service FOGService;
        }
        return;
    }

}

function Invoke-FogApi {
# .ExternalHelp FogApi-help.xml

    [CmdletBinding()]
    param (
        [string]$uriPath,
        [string]$Method="GET",
        [string]$jsonData
    )

    begin {
        Write-Verbose "Pulling settings from settings file"
        # Set-FogServerSettings;
        $serverSettings = Get-FogServerSettings;

        [string]$fogApiToken = $serverSettings.fogApiToken;
        [string]$fogUserToken = $serverSettings.fogUserToken;
        [string]$fogServer = $serverSettings.fogServer;

        $baseUri = "http://$fogServer/fog";

        # Create headers
        Write-Verbose "Building Headers...";
        $headers = @{};
        $headers.Add('fog-api-token', $fogApiToken);
        $headers.Add('fog-user-token', $fogUserToken);

        # Set the Uri
        Write-Verbose "Building api call URI...";
        $uri = "$baseUri/$uriPath";
        $uri = $uri.Replace('//','/')
        $uri = $uri.Replace('http:/','http://')


        $apiCall = @{
            Uri = $uri;
            Method = $Method;
            Headers = $headers;
            Body = $jsonData;
            ContentType = "application/json"
        }
        if ($null -eq $apiCall.Body -OR $apiCall.Body -eq "") {
            Write-Verbose "removing body from call as it is null"
            $apiCall.Remove("Body");
        }

    }

    process {
        Write-Verbose "$Method`ing $jsonData to/from $uri";
        try {
            $result = Invoke-RestMethod @apiCall -ea Stop;
        } catch {
            $result = Invoke-WebRequest @apiCall;
        }
    }

    end {
        Write-Verbose "finished api call";
        return $result;
    }

}

function New-FogObject {
# .ExternalHelp FogApi-help.xml

    [CmdletBinding()]
    param (
        # The type of object being requested
        [Parameter(Position=0)]
        [ValidateSet("objecttasktype","object")]
        [string]
        $type,
        # The json data for the body of the request
        [Parameter(Position=2)]
        [Object]$jsonData,
        # The id of the object when creating a new task
        [Parameter(Position=3)]
        [string]$IDofObject
    )

    DynamicParam { $paramDict = Set-DynamicParams $type; return $paramDict;}

    begin {
        $paramDict | % { New-Variable -Name $_.Keys -Value $($_.Values.Value);}
        Write-Verbose "Building uri and api call";
        switch ($type) {
            objecttasktype {
                $uri = "$CoreTaskObject/$IDofObject/task";
             }
            object {
                $uri = "$CoreObject/create";
            }
        }
        $apiInvoke = @{
            uriPath=$uri;
            Method="POST";
            jsonData=$jsonData;
        }
    }

    process {
        $result = Invoke-FogApi @apiInvoke;
    }

    end {
        return $result;
    }

}

function Remove-FogObject {
# .ExternalHelp FogApi-help.xml

    [CmdletBinding()]
    param (
        # The type of object being requested
        [Parameter(Position=0)]
        [ValidateSet("objecttasktype","objectactivetasktype","object")]
        [string]$type,
        # The json data for the body of the request
        [Parameter(Position=2)]
        [Object]$jsonData,
        # The id of the object to remove
        [Parameter(Position=3)]
        [string]$IDofObject
    )

    DynamicParam { $paramDict = Set-DynamicParams $type; return $paramDict;}

    begin {
        $paramDict | ForEach-Object { New-Variable -Name $_.Keys -Value $($_.Values.Value);}
        Write-Verbose "Building uri and api call";
        switch ($type) {
            objecttasktype {
                $uri = "$CoreTaskObject/$IDofObject/cancel";
             }
            object {
                $uri = "$CoreObject/$IDofObject/delete";
            }
            objectactivetasktype {
                $uri = "$CoreActiveTaskObject/cancel"
            }
        }
        $apiInvoke = @{
            uriPath=$uri;
            Method="DELETE";
            jsonData=$jsonData;
        }
        if ($apiInvoke.jsonData -eq $null -OR $apiInvoke.jsonData -eq "") {
            $apiInvoke.Remove("jsonData");
        }
    }

    process {
        $result = Invoke-FogApi @apiInvoke;
    }

    end {
        return $result;
    }

}

function Remove-UsbMac {
# .ExternalHelp FogApi-help.xml
    [CmdletBinding()]
    param (
        [string[]]$usbMacs,
        [string]$hostname = "$(hostname)",
        $macId
    )
        
    begin {
        if ($null -eq $usbMacs) {
            Write-Error "no macs to remove given";
            exit;   
        }
        Write-Verbose "remove usb ethernet adapter from host $hostname on fog server $fogServer ....";
        # get the host id by getting all hosts and searching the hosts array of the returned json for the item that has a name matching the current hostname and get the host id of that item
        $hostObj = Get-FogHost -hostName $hostname;
        $hostId = $hostObj.id;
        # $hostId = ( (Invoke-FogApi -fogServer $fogServer -fogApiToken $fogApiToken -fogUserToken $fogUserToken).hosts | Where-Object name -match "$hostname" ).id;
        # With the host id get mac associations that match that host id.
        try { 
            $macs = Get-FogObject -type object -coreObject macaddressassociation | select-object -ExpandProperty macaddressassociations | Where-Object hostID -match $hostID
        } catch {
            $macs = (Invoke-FogApi -uriPath "macaddressassociation").macaddressassociations | Where-Object hostID -match "$hostId";
        }

        # Copy the return fixedsize json array collection to a new powershell list variable for add and remove functions
        $macList = New-Object System.Collections.Generic.List[System.Object];
        try {
            $macs.ForEach({ $macList.add($_.mac); });
        } catch {
            $macs | ForEach-Object{
                $macList.add($_.mac);
            }
        }
    }

    process {
        # Check if any usbmacs are contained in the host's macs
        $usbMacs | ForEach-Object { #loop through list of usbMacs
            if ( $macList.contains($_) ) { # check if the usbMac is contained in the mac list of the host
                # Remove from the list so a new primary can be picked if needed
                $macList.Remove($_);

                Write-Verbose "$_ is a $usbMac connected to $hostname, checking if it is the primary...";
                $macItem = ($macs | Where-Object mac -eq $_ );

                if ( $macItem.primary -eq 1 ) {
                    Write-Verbose "It is primary, let's fix that and set $($macList[0]) to primary";
                    $macItem.primary = 0;
                    try {
                        Update-FogObject -type object -coreObject macaddressassociation -IDofObject $macItem.id -jsonData ($macItem | ConvertToJson)
                    } catch {   
                        $removePrimaryAttribute = @{
                            uriPath = "macaddressassociation/$($macItem.id)/edit";
                            Method = 'Put';
                            jsonData = ($macItem | ConvertTo-Json);
                        }
                        Invoke-FogApi @removePrimaryAttribute;
                    }

                    Write-Verbose "Primary attribute removed, setting new primary...";
                    $newPrimary = ($macs | Where-Object mac -eq $macList[0] );
                    if ($null -eq $newPrimary) {
                        Write-Verbose "host only has usbmacs, adding first non usbmac adapter";
                        $physicalMacs = (get-netadapter | select-object -expand macaddress).replace("-",":")
                        $physicalMacs = $physicalMacs | Where-Object {$_ -NotIn $usbMacs};
                        Add-FogHostMac -hostID $hostID -macAddress $physicalMacs[0] -primary;
                    } else {
                        $newPrimary.primary = 1;
                        $newPrimary.pending = 0;
                        Update-FogObject -type object -coreObject macaddressassociation -IDofObject $newPrimary.id -jsonData ($newPrimary | ConvertTo-Json)
                    }
                }

                Write-Verbose "Remove the usb ethernet mac association";
                try {
                    $result += Remove-FogObject -type object -coreObject macaddressassociation -IDofObject $macItem.id;
                } catch {
                    $removeMacAssoc = @{
                        uriPath = "macaddressassociation/$($macItem.id)/delete";
                        Method = 'Delete';
                    }
                    $result += Invoke-FogApi @removeMacAssoc;
                }
                Write-Verbose "Usb macs $usbMacs have been removed from $hostname on the $fogServer";
            }
        }
    }

    end {
        if ($null -eq $result) {
            $result = "no usb adapters found"; #replace string if found
        }
        return $result;
    }

}

function Reset-HostEncryption {
# .ExternalHelp FogApi-help.xml
    
    [CmdletBinding()]
    param (
        $fogHost = (Get-FogHost),
        [switch]$restartSvc
     )

    process {
        $fogHost.pub_key = "";
        $fogHost.sec_tok = "";
        $fogHost.sec_time = "0000-00-00 00:00:00";

        $jsonData = $fogHost | Select-Object id,pub_key,sec_tok,sec-time | ConvertTo-Json;
        $result = Update-FogObject -type object -coreObject host -IDofObject $fogHost.id -jsonData $jsonData;
        if ($restartSvc) {
            Restart-Service fogservice -force;
        }
        return $result;
    }
    
}

function Set-FogInventory {
# .ExternalHelp FogApi-help.xml

    [CmdletBinding()]
    param (
        $hostObj = (Get-FogHost),
        $jsonData = (Get-FogInventory -hostObj $hostObj)
    )

    begin {
        $inventoryApi = @{
            jsonData = $jsonData;
            Method = 'Post';
            uriPath = "inventory/new";
        }
    }

    process {
        Invoke-FogApi @inventoryApi -verbose;
    }

    end {
        return;
    }

}

function Set-FogServerSettings {
# .ExternalHelp FogApi-help.xml

    [CmdletBinding()]
    param (
        [string]$fogApiToken,
        [string]$fogUserToken,
        [string]$fogServer,
        [switch]$interactive
    )
    begin {
        
        $settingsFile = "$ENV:APPDATA\FogApi\api-settings.json"
        if (!(Test-path $settingsFile)) {
            if (!(Test-Path "$ENV:APPDATA\FogApi")) {
                mkdir "$ENV:APPDATA\FogApi";
            }
            Copy-Item "$tools\settings.json" $settingsFile -Force
        }
        $ServerSettings = Get-FogServerSettings;
        Write-Verbose "Current/old Settings are $($ServerSettings)";
        $helpTxt = @{
            fogApiToken = "fog API token found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System";
            fogUserToken = "your fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab";
            fogServer = "your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer";
        }
        
    }
    
    process {
        if($null -ne $fogApiToken -and $null -ne $fogUserToken -AND $null -ne $fogServer) {
            $serverSettings = @{
                fogApiToken = $fogApiToken;
                fogUserToken = $fogUserToken;
                fogServer = $fogServer;
            }
        }
        # If given paras are null just pulls from settings file
        # If they are not null sets the object to passed value
        if($interactive) {
            $serverSettings.psobject.properties | ForEach-Object {
                $var = (Get-Variable -Name $_.Name);
                if ($null -eq $var.Value -OR $var.Value -eq "") {
                        Set-Variable -name $var.Name -Value (Read-Host -Prompt "Enter the $($var.name), help message: $($helpTxt.($_.name)) ");        
                }
            }
        }
        

        Write-Verbose "making sure all settings are set";
        if ( $ServerSettings.fogApiToken -eq $helpTxt.fogApiToken -OR
            $ServerSettings.fogUserToken -eq $helpTxt.fogUserToken -OR $ServerSettings.fogServer -eq $helpTxt.fogServer) {
            Write-Host -BackgroundColor Yellow -ForegroundColor Red -Object "a fog setting is still set to its default help text, opening the settings file for you to set the settings"
            Write-Host -BackgroundColor Yellow -ForegroundColor Red -Object "This script will close after opening settings in notepad, please re-run command after updating settings file";
            if ($isLinux) {
                $editor = 'nano';
            }
            elseif($IsMacOS) {
                $editor = 'TextEdit';
            }
            else {
                $editor = 'notepad.exe';
            }
            Start-Process -FilePath $editor -ArgumentList "$SettingsFile" -NoNewWindow -PassThru;
            return;
        }
    }

    end {
        Write-Verbose "Writing new Settings";
        $serverSettings | ConvertTo-Json | Out-File -FilePath $settingsFile -Encoding oem -Force;
        return (Get-Content $settingsFile | ConvertFrom-Json);
    }

}

function Set-FogSnapins {
# .ExternalHelp FogApi-help.xml

    [CmdletBinding()]
    [Alias('Add-FogSnapins')]
    param (
        $hostid = ((Get-FogHost).id),
        $pkgList,
        $dept
    )

    process {
        Write-Verbose "Association snapins from package list with host";
        $snapins = Get-FogSnapins;
        # $urlPath = "snapinassociation/create"
        $curSnapins = Get-FogAssociatedSnapins -hostId $hostid;
        $result = New-Object System.Collections.Generic.List[Object];
        if ($null -ne $pkgList) {
            $pkgList | ForEach-Object {
                $json = @{
                    hostID = $hostid
                    snapinID = (($snapins | Where-Object name -match "$($_)").id);
                };
                Write-Verbose "$_ is pkg snapin id found is $($json.snapinID)";
                if (($null -ne $json.SnapinID) -AND ($json.SnapinID -notin $curSnapins.id)) {
                    $json = $json | ConvertTo-Json;
                    $result.add((New-FogObject -type object -coreObject snapinassociation -jsonData $json));
                } elseif ($json.SnapinID -in $curSnapins.id) {
                    Write-Warning "$_ snapin of id $($json.SnapinID) is already associated with this host";
                } else {
                    Write-Warning "no snapin ID found for $_ pkg";
                }
                # Invoke-FogApi -Method POST -uriPath $urlPath -jsonData $json;
            }
        }
        return $result;
    }


}

function Start-FogSnapins {
# .ExternalHelp FogApi-help.xml

    [CmdletBinding()]
    param (
        $hostid = ((Get-FogHost).id),
        $taskTypeid = 12
    )

    begin {
        Write-Verbose "Stopping any queued snapin tasks";
        try {
            $tasks = Get-FogObject -type objectactivetasktype -coreActiveTaskObject task;
        } catch {
            $tasks = Invoke-FogApi -Method GET -uriPath "task/active";
        }
        $taskID = (($tasks | Where-Object hostID -match $hostid).id);
        Write-Verbose "Found $($taskID.count) tasks deleting them now";
        $taskID | ForEach-Object{
            try {
                Remove-FogObject -type objecttasktype -coreTaskObject task -IDofObject $_;
            } catch {
                Invoke-FogApi -Method DELETE -uriPath "task/$_/cancel";
            }
        }
        # $snapAssocs = Invoke-FogApi -uriPath snapinassociation -Method Get;
        # $snaps = $snapAssocs.snapinassociations | ? hostid -eq $hostid;
    }

    process {
        Write-Verbose "starting all snapin task for host";
        $json = (@{
            "taskTypeID"=$taskTypeid;
            "deploySnapins"=-1;
        } | ConvertTo-Json);
        New-FogObject -type objecttasktype -coreTaskObject host -jsonData $json -IDofObject $hostid;
    }

    end {
        Write-Verbose "Snapin tasks have been queued on the server";
        return;
    }

}

function Update-FogObject {
# .ExternalHelp FogApi-help.xml
    [CmdletBinding()]
    [Alias('Set-FogObject')]
    param (
        # The type of object being requested
        [Parameter(Position=0)]
        [ValidateSet("object")]
        [string]$type,
        # The json data for the body of the request
        [Parameter(Position=2)]
        [Object]$jsonData,
        # The id of the object to remove
        [Parameter(Position=3)]
        [string]$IDofObject,
        [Parameter(Position=4)]
        [string]$uri
    )

    DynamicParam { $paramDict = Set-DynamicParams $type; return $paramDict; }

    begin {
        $paramDict | ForEach-Object { New-Variable -Name $_.Keys -Value $($_.Values.Value);}
        Write-Verbose "Building uri and api call";
        if([string]::IsNullOrEmpty($uri)) {
            $uri = "$CoreObject/$IDofObject/edit";
        }

        $apiInvoke = @{
            uriPath=$uri;
            Method="PUT";
            jsonData=$jsonData;
        }
    }

    process {
        $result = Invoke-FogApi @apiInvoke;
    }

    end {
        return $result;
    }

}

function Get-DynmicParam {
<#
.SYNOPSIS
Gets the dynamic parameter for the main functions

.DESCRIPTION
Dynamically sets the correct tab completeable validate set for the coreobject, coretaskobject, coreactivetaskobject, or string to search

.PARAMETER paramName
the name of the parameter being dynamically set within the validate set

.PARAMETER position
the position to put the dynamic parameter in

#>

    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [ValidateSet('coreObject','coreTaskObject','coreActiveTaskObject','stringToSearch')]
        [string]$paramName,
        $position=1
    )
    begin {
        #initilzie objects
        $attributes = New-Object Parameter; #System.Management.Automation.ParameterAttribute;
        $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        # $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Set attributes
        $attributes.Position = $position;
        $attributes.Mandatory = $true;

        $attributeCollection.Add($attributes)

        $coreObjects = @(
            "clientupdater", "dircleaner", "greenfog", "group", "groupassociation",
            "history", "hookevent", "host", "hostautologout", "hostscreensetting", "image",
            "imageassociation", "imagepartitiontype", "imagetype", "imaginglog", "inventory", "ipxe",
            "keysequence", "macaddressassociation", "module", "moduleassociation", "multicastsession",
            "multicastsessionsassociation", "nodefailure", "notifyevent", "os", "oui", "plugin",
            "powermanagement", "printer", "printerassociation", "pxemenuoptions", "scheduledtask",
            "service", "snapin", "snapinassociation", "snapingroupassociation", "snapinjob",
            "snapintask", "storagegroup", "storagenode", "task", "tasklog", "taskstate", "tasktype",
            "usercleanup", "usertracking", "virus"
        );
        $coreTaskObjects = @("group", "host", "multicastsession", "snapinjob", "snapintask", "task");
        $coreActiveTaskObjects = @("multicastsession", "scheduledtask", "snapinjob", "snapintask", "task");
    }

    process {
        switch ($paramName) {
            coreObject { $attributeCollection.Add((New-Object ValidateSet($coreObjects)));}
            coreTaskObject {$attributeCollection.Add((New-Object ValidateSet($coreTaskObjects)));}
            coreActiveTaskObject {$attributeCollection.Add((New-Object ValidateSet($coreActiveTaskObjects)));}
        }
        $dynParam = New-Object System.Management.Automation.RuntimeDefinedParameter($paramName, [string], $attributeCollection);
        # $paramDictionary.Add($paramName, $dynParam);
    }
    end {
        return $dynParam;
    }

}
function Set-DynamicParams {
<#
.SYNOPSIS
Sets the dynamic param dictionary

.DESCRIPTION
Sets dynamic parameters inside functions

.PARAMETER type
the type of parameter

#>

    [CmdletBinding()]
    param ($type)
    $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary;

    # Sub function for setting
    function Set-Param($paramName) {
        $param = Get-DynmicParam -paramName $paramName;
        $paramDictionary.Add($paramName, $param);
    }
    switch ($type) {
        object { Set-Param('coreObject');}
        objectactivetasktype { Set-Param('coreActiveTaskObject');}
        objecttasktype {Set-Param('coreTaskObject');}
        search {Set-Param('stringToSearch');}
    }
    return $paramDictionary;

}
