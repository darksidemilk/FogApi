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
        [ValidateSet('coreObject','coreTaskObject','coreActiveTaskObject')]
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

        if ((Get-FogVersion) -like '1.6*') {
            $coreObjects = @(
                "group", "groupassociation", "history", "hookevent", "host", "hostautologout", 
                "hostscreensetting", "image", "imageassociation", "imagepartitiontype", "imagetype", 
                "imaginglog", "inventory", "ipxe", "keysequence", "macaddressassociation", "module", 
                "moduleassociation", "multicastsession", "multicastsessionassociation", "nodefailure", 
                "notifyevent", "os", "oui", "plugin", "powermanagement", "printer", "printerassociation", 
                "pxemenuoptions", "scheduledtask", "setting", "snapin", "snapinassociation", 
                "snapingroupassociation", "snapinjob", "snapintask", "storagegroup", "storagenode", "task", 
                "tasklog", "taskstate", "tasktype", "unisearch", "user", "usertracking", "setting", "user"
            );
        } else {
            $coreObjects = @(
                "clientupdater", "dircleaner", "greenfog", "group", "groupassociation",
                "history", "hookevent", "host", "hostautologout", "hostscreensetting", "image",
                "imageassociation", "imagepartitiontype", "imagetype", "imaginglog", "inventory", "ipxe",
                "keysequence", "macaddressassociation", "module", "moduleassociation", "multicastsession",
                "multicastsessionassociation", "nodefailure", "notifyevent", "os", "oui", "plugin",
                "powermanagement", "printer", "printerassociation", "pxemenuoptions", "scheduledtask",
                "service", "setting", "snapin", "snapinassociation", "snapingroupassociation", "snapinjob",
                "snapintask", "storagegroup", "storagenode", "task", "tasklog", "taskstate", "tasktype",
                "unisearch", "user", "usercleanup", "usertracking", "virus"
            );
        }

        $coreTaskObjects = @("group", "host", "multicastsession", "scheduledtask", "snapinjob", "snapintask", "task");
        $coreActiveTaskObjects = @("multicastsession", "powermanagement", "scheduledtask", "snapinjob", "snapintask", "task");
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
