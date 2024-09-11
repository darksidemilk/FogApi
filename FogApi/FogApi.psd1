#
# Module manifest for module 'FogApi'
#
# Generated by: JJ Fullmer
#
# Generated on: 9/11/2024
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'FogApi.psm1'

# Version number of this module.
ModuleVersion = '2409.9.14'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '7aa922fa-bb4f-46a0-a478-684e9535c65d'

# Author of this module
Author = 'JJ Fullmer'

# Company or vendor of this module
CompanyName = 'FOG Project'

# Copyright statement for this module
Copyright = '2018-2024'

# Description of the functionality provided by this module
Description = '
# FOG Api Powershell Module

This is a powershell module to simplify the use of the Fog Project API.
This module is used to easily run Fog API commands on your fogserver from a powershell console or script.
FOG is an opensource tool for imaging comptuters, this module uses the API on your internal fog server to 
perform almost any operation you can do in the GUI of Fog and provides you with the ability to extend things further.
It can be used to create more automation or to simply have a command line method of controlling fog operations.
This essentially gives you a crossplatform commandline interface for fog tasks and makes many things easier to automate.

Docs for this module can be found at https://fogapi.readthedocs.io/en/latest/

For more information about FOG see

- https://FOGProject.org
- https://docs.fogproject.org
- https://github.com/FOGProject
- https://github.com/FOGProject/fogproject
- https://forums.fogproject.org

# Versioning

The versioning of this module follows this pattern

`{Year|Month}.{Major Version}.{Revision #}`

## Year/Month

This versioning shows you first the Year and month this version of the module was published, giving you an idea of when it was last updated.
i.e. 2208 would be august 2022.

## Major

The Major version follows the typical major versioning where any major changes will increment this version number, especially possible breaking changes or structural changes, etc.

## Minor/Revision

Any time I publish a new version that isn''t a major change I''ll increment the revision. This may also be incremented for each build test and increment by more than one for each published version

# Usage

You can use Set-fogserverSettings to set your fogserver hostname and api keys.
The first time you try to run a command the settings.json file will automatically open
in notepad on windows, nano on linux, or TextEdit on Mac
You can also open the settings.json file and edit it manually before running your first command.
The default settings are explanations of where to find the proper settings since json can''''t have comments

Once the settings are set you can have a jolly good time utilzing the fog documentation
found here https://news.fogproject.org/simplified-api-documentation/ that was used to model the parameters

See https://github.com/darksidemilk/FogApi/blob/master/README.md for more examples and see https://fogapi.readthedocs.io/en/latest/commands/ for a list of all the commands

# Additional info

See also the fogforum thread for the module https://forums.fogproject.org/topic/12026/powershell-api-module/2
Full change log available at https://fogapi.readthedocs.io/en/latest/ReleaseNotes/
'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '3.0'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Add-FogHostMac', 'Add-FogResultData', 'Approve-FogPendingMac', 
               'Deny-FogPendingMac', 'Disable-FogApiHTTPS', 'Dismount-WinEfi', 
               'Enable-FogApiHTTPS', 'Find-FogObject', 'Get-FogActiveTasks', 
               'Get-FogGroupAssociations', 'Get-FogGroupByName', 'Get-FogGroups', 
               'Get-FogHost', 'Get-FogHostAssociatedSnapins', 'Get-FogHostGroup', 
               'Get-FogHostMacs', 'Get-FogHostPendingMacs', 'Get-FogHosts', 
               'Get-FogImages', 'Get-FogInventory', 'Get-FogLog', 
               'Get-FogMacAddresses', 'Get-FogModules', 'Get-FogObject', 
               'Get-FogSecsSinceEpoch', 'Get-FogServerSettings', 
               'Get-FogServerSettingsFile', 'Get-FogSetting', 'Get-FogSettings', 
               'Get-FogSnapinAssociations', 'Get-FogSnapins', 'Get-FogVersion', 
               'Get-LastImageTime', 'Get-WinBcdPxeID', 'Get-WinEfiMountLetter', 
               'Install-FogService', 'Invoke-FogApi', 'Mount-WinEfi', 'New-FogHost', 
               'New-FogObject', 'Receive-FogImage', 'Remove-FogObject', 
               'Remove-UsbMac', 'Repair-FogSnapinAssociations', 
               'Reset-HostEncryption', 'Resolve-HostID', 'Send-FogImage', 
               'Send-FogWolTask', 'Set-FogHostImage', 'Set-FogInventory', 
               'Set-FogServerSettings', 'Set-FogServerSettingsFileSecurity', 
               'Set-FogSetting', 'Set-FogSnapins', 'Set-WinToBootToPxe', 
               'Start-FogSnapin', 'Start-FogSnapins', 'Test-FogVerAbove1dot6', 
               'Test-StringNotNullOrEmpty', 'Update-FogObject'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = 'Add-FogHost', 'Add-FogObject', 'Add-FogSnapins', 'Capture-FogImage', 
               'Deploy-FogImage', 'Get-FogAssociatedSnapins', 'Get-FogGroup', 
               'Get-FogHostInventory', 'Get-FogHostSnapinAssociations', 
               'Get-FogHostSnapins', 'Get-FogMacs', 'Get-MacsForHost', 
               'Get-WinInventoryForFog', 'Invoke-FogImageCapture', 'Pull-FogImage', 
               'Push-FogImage', 'Remove-FogMac', 'Save-FogImage', 'Set-FogObject'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'fog', 'fogapi', 'imaging', 'provisioning', 'fogproject'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/darksidemilk/FogApi/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/darksidemilk/FogApi'

        # A URL to an icon representing this module.
        IconUri = 'https://cdn.statically.io/gh/darksidemilk/FogApi/0ed5e87e/FogApi/icons/favicon.png'

        # ReleaseNotes of this module
        ReleaseNotes = '
# 2409.9.14

	Filter out rdp display driver when getting host inventory details and append video memory in GB to each adapter name

Full change log history available at https://fogapi.readthedocs.io/en/latest/ReleaseNotes/'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable


    # Title
    Title = 'FogApi'

} # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://fogapi.readthedocs.io/en/latest/'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

