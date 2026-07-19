function Update-FogGroup {
<#
    .SYNOPSIS
    Updates a fog group's own fields

    .DESCRIPTION
    Edits the group object itself (name, description, kernel options, etc.) rather than its host membership.
    Use Add-FogHostGroup/Remove-FogHostGroup to add or remove a single host at a time.

    You can either:
    - Pipe in a group object (e.g. from Get-FogGroups/Get-FogGroupByName), change its properties directly, and
      pipe the modified object back in - the changed scalar fields (name, description, building, kernel,
      kernelArgs, kernelDevice, init) are sent automatically.
    - Use the named parameters below directly against -groupID or a piped group object. Named parameters always
      take precedence over whatever is present on a piped object.

    .PARAMETER groupObj
    A fog group object (e.g. from Get-FogGroups) to update. Supports pipeline input. Its own name/description/
    building/kernel/kernelArgs/kernelDevice/init properties are sent as-is unless overridden by a named parameter.

    .PARAMETER groupID
    The id of the group to update

    .PARAMETER Name
    The group's name

    .PARAMETER Description
    The group's description

    .PARAMETER Building
    The building associated with the group

    .PARAMETER Kernel
    The kernel file name to use for hosts in this group

    .PARAMETER KernelArgs
    The kernel arguments to use for hosts in this group

    .PARAMETER KernelDevice
    The primary disk/device to use for hosts in this group

    .PARAMETER Init
    The init/initrd setting for hosts in this group

    .PARAMETER Hosts
    Full replacement list of host ids that should be members of this group. Fog diffs this against the group's
    current membership and adds/removes hosts accordingly. For adding/removing a single host, prefer
    Add-FogHostGroup/Remove-FogHostGroup instead.

    .PARAMETER Snapins
    Full replacement list of snapin ids to associate with every host currently in this group

    .PARAMETER Printers
    Full replacement list of printer ids to associate with every host currently in this group

    .PARAMETER Modules
    Full replacement list of module ids to associate with every host currently in this group

    .PARAMETER ImageID
    Assigns this image id to every host currently in this group. Fails if any member host is currently mid-task.

    .PARAMETER settings
    Escape hatch: a hashtable of any additional group fields to change, sent alongside/underneath the named
    parameters above. Useful for fields not otherwise exposed as a named parameter.

    .EXAMPLE
    Update-FogGroup -groupID 7 -Description "Lab computers"

    Updates the description field of the group with id 7

    Expected output:
    { "description": "Lab computers" }

    .EXAMPLE
    $g = Get-FogGroupByName "TestGroup"; $g.description = "Updated via example"; $g | Update-FogGroup

    Gets the group named "TestGroup", edits its description property directly on the returned object, and sends the
    change back with the modified object piped straight into Update-FogGroup.

    Expected output:
    { "description": "Updated via example" }

    .EXAMPLE
    Get-FogGroupByName "Lab" | Update-FogGroup -ImageID 12

    Finds the group named "Lab" and assigns image id 12 to every host currently in that group.

    .NOTES
    Verified against the fog server source (FOGProject/fogproject, working-1.6 and dev-branch, identical on
    both): Group's databaseFields are name/description/createdBy/createdTime/building/kernel/kernelArgs/
    kernelDevice/init (only "name" is required), and the group edit route additionally special-cases
    hosts/snapins/printers/modules/imageID to cascade the change to every member host.
#>

    [CmdletBinding(DefaultParameterSetName='byId')]
    [Alias('Set-FogGroup')]
    param (
        [parameter(ValueFromPipeline=$true,ParameterSetName='byObj')]
        $groupObj,
        [parameter(Mandatory=$true,ParameterSetName='byId')]
        $groupID,
        [string]$Name,
        [string]$Description,
        [string]$Building,
        [string]$Kernel,
        [string]$KernelArgs,
        [string]$KernelDevice,
        [string]$Init,
        [int[]]$Hosts,
        [int[]]$Snapins,
        [int[]]$Printers,
        [int[]]$Modules,
        [int]$ImageID,
        [hashtable]$settings
    )

    process {
        if ($null -ne $_) {
            $groupObj = $_;
        }
        if ($null -ne $groupObj) {
            $groupID = $groupObj.id;
        }

        $fields = @{};

        if ($null -ne $settings) {
            foreach ($key in $settings.Keys) {
                $fields[$key] = $settings[$key];
            }
        }

        if ($null -ne $groupObj) {
            foreach ($prop in @('name', 'description', 'building', 'kernel', 'kernelArgs', 'kernelDevice', 'init')) {
                if ($null -ne $groupObj.$prop) {
                    $fields[$prop] = $groupObj.$prop;
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('Name')) { $fields['name'] = $Name }
        if ($PSBoundParameters.ContainsKey('Description')) { $fields['description'] = $Description }
        if ($PSBoundParameters.ContainsKey('Building')) { $fields['building'] = $Building }
        if ($PSBoundParameters.ContainsKey('Kernel')) { $fields['kernel'] = $Kernel }
        if ($PSBoundParameters.ContainsKey('KernelArgs')) { $fields['kernelArgs'] = $KernelArgs }
        if ($PSBoundParameters.ContainsKey('KernelDevice')) { $fields['kernelDevice'] = $KernelDevice }
        if ($PSBoundParameters.ContainsKey('Init')) { $fields['init'] = $Init }
        if ($PSBoundParameters.ContainsKey('Hosts')) { $fields['hosts'] = $Hosts }
        if ($PSBoundParameters.ContainsKey('Snapins')) { $fields['snapins'] = $Snapins }
        if ($PSBoundParameters.ContainsKey('Printers')) { $fields['printers'] = $Printers }
        if ($PSBoundParameters.ContainsKey('Modules')) { $fields['modules'] = $Modules }
        if ($PSBoundParameters.ContainsKey('ImageID')) { $fields['imageID'] = $ImageID }

        if ($fields.Count -eq 0) {
            Write-Warning "No group fields were provided to update - nothing to do"
            return $null;
        }

        return Update-FogObject -type object -coreObject group -IDofObject $groupID -jsonData ($fields | ConvertTo-Json)
    }

}
