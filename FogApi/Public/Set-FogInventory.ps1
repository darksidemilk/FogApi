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
        $hostObj = (Get-FogHost),
        $jsonData = (Get-FogInventory -hostObj $hostObj)
    )

    process {
        $inventoryApi = @{
            jsonData = $jsonData;
            Method = 'Post';
            uriPath = "inventory/new";
        }
        Invoke-FogApi @inventoryApi -verbose;
        return;
    }

}
