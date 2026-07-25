function New-FogSnapin {
    [CmdletBinding()]
    param (
        $name,
        $description,
        $existingFileName,
        $newFilePath,
        $fileArgs,
        [switch]$reboot,
        [switch]$shutdown,
        $runWith = "powershell.exe",
        $runWithArgs,
        [switch]$protected,
        [bool]$enabled = $true,
        [bool]$replicate = $true,
        [bool]$hide = $false,
        $timeout = 0,
        $packtype = 0,
        $storagegroupID = 1
    )
    
    process {
        $hash = Get-FileHash -path $newFilePath -Algorithm SHA256 | Select-Object -ExpandProperty Hash;
        
        $json = @{
            "name"="$Name"
            "description"=$description
            "file"=$newFilePath
            "args"=$fileArgs
            "reboot"=""
            "shutdown"=""
            "runWith"=$runWith
            "runWithArgs"="-ExecutionPolicy Bypass -NoProfile -File"
            "protected"="0"
            "isEnabled"="1"
            "toReplicate"="1"
            "hide"="0"
            "timeout"="0"
            "packtype"="0"
            "storagegroupID"="1"
            "hash"="$hash"
            "size"="$fileSize"
            "anon3"=""
        } | ConvertTo-Json;
        
        New-FogObject -type object -coreObject snapin -jsonData $json;
    }
    
}