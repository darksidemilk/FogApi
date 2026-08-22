function Get-FogCoreObjectList {
<#
.SYNOPSIS
The -coreObject ValidateSet values for a given fog version.

.DESCRIPTION
GENERATED FILE. Do not edit. Rebuild with spec/tools/New-FogCoreObjectList.ps1.

The 1.6 list is every route class the server serves, taken from
spec/fog-api-spec.json, which is built from the server's own OpenAPI document.
It used to be typed into Get-DynmicParam and had drifted by seven classes --
role, rolepermission, roleuserassociation, roleusergroupassociation, usergroup,
usergroupmember and filedeletequeue -- which made every L1 call for those fail
during parameter binding rather than at the server.

Two entries are not route classes and are kept deliberately, because removing a
ValidateSet entry breaks callers while adding one never does:

  unisearch        Find-FogObject's sentinel for a universal search
  siteassociation  a spelling older callers may already pass

The 1.5 list is hand-maintained: that line ships no schema manifest, so there is
nothing to generate it from, and a generated one would be a guess.

.PARAMETER version
The fog version string, as Get-FogVersion reports it.

.EXAMPLE
Get-FogCoreObjectList -version '1.6.0'

Returns the 1.6 class names.
#>
    [CmdletBinding()]
    param (
        [string]$version
    )

    process {
        if ($version -like '1.6*') {
            return @(
            'filedeletequeue', 'group', 'groupassociation', 'history', 'hookevent', 'host',
            'hostautologout', 'hostscreensetting', 'image', 'imageassociation', 'imagepartitiontype', 'imagetype',
            'inventory', 'ipxe', 'keysequence', 'macaddressassociation', 'module', 'moduleassociation',
            'multicastsession', 'multicastsessionassociation', 'nodefailure', 'notifyevent', 'os', 'oui',
            'plugin', 'powermanagement', 'printer', 'printerassociation', 'pxemenuoptions', 'role',
            'rolepermission', 'roleuserassociation', 'roleusergroupassociation', 'scheduledtask', 'setting', 'site',
            'siteassociation', 'snapin', 'snapinassociation', 'snapingroupassociation', 'snapinjob', 'snapintask',
            'storagegroup', 'storagenode', 'task', 'tasklog', 'taskstate', 'tasktype',
            'unisearch', 'user', 'usergroup', 'usergroupmember', 'usertracking'
            )
        }
        return @(
            'clientupdater', 'dircleaner', 'greenfog', 'group', 'groupassociation',
            'history', 'hookevent', 'host', 'hostautologout', 'hostscreensetting',
            'image', 'imageassociation', 'imagepartitiontype', 'imagetype',
            'imaginglog', 'inventory', 'ipxe', 'keysequence', 'macaddressassociation',
            'module', 'moduleassociation', 'multicastsession',
            'multicastsessionassociation', 'nodefailure', 'notifyevent', 'os', 'oui',
            'plugin', 'powermanagement', 'printer', 'printerassociation',
            'pxemenuoptions', 'scheduledtask', 'service', 'setting', 'snapin',
            'snapinassociation', 'snapingroupassociation', 'snapinjob', 'snapintask',
            'storagegroup', 'storagenode', 'task', 'tasklog', 'taskstate', 'tasktype',
            'unisearch', 'user', 'usercleanup', 'usertracking', 'virus'
        )
    }

}
