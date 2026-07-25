---
external help file: FogApi-help.xml
Module Name: FogApi
online version: https://fogapi.readthedocs.io/en/latest/commands/Update-FogGroup
schema: 2.0.0
---

# Update-FogGroup

## SYNOPSIS
Updates a fog group's own fields

## SYNTAX

### byId (Default)
```
Update-FogGroup -groupID <Object> [-Name <String>] [-Description <String>] [-Building <String>]
 [-Kernel <String>] [-KernelArgs <String>] [-KernelDevice <String>] [-Init <String>] [-Hosts <Int32[]>]
 [-Snapins <Int32[]>] [-Printers <Int32[]>] [-Modules <Int32[]>] [-ImageID <Int32>] [-settings <Hashtable>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### byObj
```
Update-FogGroup [-groupObj <Object>] [-Name <String>] [-Description <String>] [-Building <String>]
 [-Kernel <String>] [-KernelArgs <String>] [-KernelDevice <String>] [-Init <String>] [-Hosts <Int32[]>]
 [-Snapins <Int32[]>] [-Printers <Int32[]>] [-Modules <Int32[]>] [-ImageID <Int32>] [-settings <Hashtable>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Edits the group object itself (name, description, kernel options, etc.) rather than its host membership.
Use Add-FogHostGroup/Remove-FogHostGroup to add or remove a single host at a time.

You can either:
- Pipe in a group object (e.g.
from Get-FogGroups/Get-FogGroupByName), change its properties directly, and
  pipe the modified object back in - the changed scalar fields (name, description, building, kernel,
  kernelArgs, kernelDevice, init) are sent automatically.
- Use the named parameters below directly against -groupID or a piped group object.
Named parameters always
  take precedence over whatever is present on a piped object.

## EXAMPLES

### EXAMPLE 1
```
Update-FogGroup -groupID 7 -Description "Lab computers"
```

Updates the description field of the group with id 7

Expected output:
{ "description": "Lab computers" }

### EXAMPLE 2
```
$g = Get-FogGroupByName "TestGroup"; $g.description = "Updated via example"; $g | Update-FogGroup
```

Gets the group named "TestGroup", edits its description property directly on the returned object, and sends the
change back with the modified object piped straight into Update-FogGroup.

Expected output:
{ "description": "Updated via example" }

### EXAMPLE 3
```
Get-FogGroupByName "Lab" | Update-FogGroup -ImageID 12
```

Finds the group named "Lab" and assigns image id 12 to every host currently in that group.

## PARAMETERS

### -groupObj
A fog group object (e.g.
from Get-FogGroups) to update.
Supports pipeline input.
Its own name/description/
building/kernel/kernelArgs/kernelDevice/init properties are sent as-is unless overridden by a named parameter.

```yaml
Type: Object
Parameter Sets: byObj
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -groupID
The id of the group to update

```yaml
Type: Object
Parameter Sets: byId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The group's name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
The group's description

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Building
The building associated with the group

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Kernel
The kernel file name to use for hosts in this group

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KernelArgs
The kernel arguments to use for hosts in this group

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KernelDevice
The primary disk/device to use for hosts in this group

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Init
The init/initrd setting for hosts in this group

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Hosts
Full replacement list of host ids that should be members of this group.
Fog diffs this against the group's
current membership and adds/removes hosts accordingly.
For adding/removing a single host, prefer
Add-FogHostGroup/Remove-FogHostGroup instead.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Snapins
Full replacement list of snapin ids to associate with every host currently in this group

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Printers
Full replacement list of printer ids to associate with every host currently in this group

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Modules
Full replacement list of module ids to associate with every host currently in this group

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ImageID
Assigns this image id to every host currently in this group.
Fails if any member host is currently mid-task.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -settings
Escape hatch: a hashtable of any additional group fields to change, sent alongside/underneath the named
parameters above.
Useful for fields not otherwise exposed as a named parameter.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Verified against the fog server source (FOGProject/fogproject, working-1.6 and dev-branch, identical on
both): Group's databaseFields are name/description/createdBy/createdTime/building/kernel/kernelArgs/
kernelDevice/init (only "name" is required), and the group edit route additionally special-cases
hosts/snapins/printers/modules/imageID to cascade the change to every member host.

## RELATED LINKS
