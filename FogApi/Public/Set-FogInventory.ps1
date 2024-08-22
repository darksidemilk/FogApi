function Set-FogInventory {
<#
.SYNOPSIS
Sets a fog hosts inventory

.DESCRIPTION
Sets the inventory of a fog host object to json data gotten from get-foginventory

.PARAMETER hostObj
the host object to set on 

.PARAMETER jsonData
the jsondata with the inventory


#>

    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline=$true)]
        $hostObj = (Get-FogHost),
        $jsonData
    )

    process {
        if ($null -ne $_) {
            $hostObj = $_;
        }
        if ($null -eq $jsonData) {
            $jsonData = (Get-FogInventory -hostObj $hostObj)
        } 
        $inventoryApi = @{
            jsonData = $jsonData;
            Method = 'Post';
            uriPath = "inventory/new";
        }
        Invoke-FogApi @inventoryApi -verbose;
        $jsonData = (Get-FogInventory -hostObj $hostObj)
        return;
    }

}
