#
# Module manifest for module 'FogApi'
#
# Generated by: JJ Fullmer
#
# Generated on: 11/17/2023
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'FogApi.psm1'

# Version number of this module.
ModuleVersion = '2311.6.4'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '7aa922fa-bb4f-46a0-a478-684e9535c65d'

# Author of this module
Author = 'JJ Fullmer'

# Company or vendor of this module
CompanyName = 'FOG Project'

# Copyright statement for this module
Copyright = '(c) 2018 JJ Fullmer. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This module is used to easily run Fog API commands on your fogserver from a powershell console or script.
    This essentially gives you a crossplatform commandline interface for fog tasks and makes many things easier to automate.

    The documentation is hosted on readthedocs at https://fogapi.readthedocs.io/en/latest/

    To install this module you need at least powershell v3, was created with 5.1 and intended to be cross platform compatible with powershell v6
    To Install this module follow these steps
    * Easiest method: Install from PSGallery https://www.powershellgallery.com/packages/FogApi Install-Module -name fogApi

    * Manual Method:
    * download the zip of this repo and extract it and use Import-Module on the extracted path

    The module is now installed.
    You can use Set-fogserverSettings to set your fogserver hostname and api keys.
    The first time you try to run a command the settings.json file will automatically open
    in notepad on windows, nano on linux, or TextEdit on Mac
    You can also open the settings.json file and edit it manually before running your first command.
    The default settings are explanations of where to find the proper settings since json can''''t have comments

    Once the settings are set you can have a jolly good time utilzing the fog documentation
    found here https://news.fogproject.org/simplified-api-documentation/ that was used to model the parameters

    i.e.

    Get-FogObject has a type param that validates to object, objectactivetasktype, and search as those are the options given in the documentation.
    Each of those types validates (which means autocompletion) to the core types listed in the documentation.
    So if you typed in Get-FogObject -Type object -Object  h and then started hitting tab, it would loop through the possible core objects you can get from the api that start with ''''h'''' such as history, host, etc.

    Unless you filter a get with a json body it will return all the results into a powershell object. That object is easy to work with to create other commands. Note: Full Pipeline support will come at a later time
     i.e.

     hosts = Get-FogObject -Type Object -CoreObject Host # calls get on http://fog-server/fog/host to list all hosts
     Now you can search all your hosts for the one or ones you''''re looking for with powershell
     maybe you want to find all the hosts with ''''IT'''' in the name  (note ''''?'''' is an alias for Where-Object)
    ITHosts = hosts.hosts | ? name -match ''''IT'''';

    Now maybe you want to change the image all of these computers use to one named ''''IT-Image''''
    You can edit the object in powershell with a foreach-object (''''%'''' is an alias for foreach-object)
    updatedITHosts = ITHosts | % { _.imagename = ''''IT-image''''}

    Then you need to convert that object to json and pass each object into one api call at a time. Which sounds complicated, but it''''s not, it''''s as easy as
    
    updateITHosts | % {
        jsonData = _ | ConvertTo-Json;
        Update-FogObject -Type object -CoreObject host -objectID _.id -jsonData jsonData;
        #successful result of updated objects properties
        #or any error messages will output to screen for each object
    }
    
    This is just one small example of the limitless things you can do with the api and powershell objects.

    see also the fogforum thread for the module https://forums.fogproject.org/topic/12026/powershell-api-module/2
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
               'Deny-FogPendingMac', 'Find-FogObject', 'Get-FogActiveTasks', 
               'Get-FogGroupAssociations', 'Get-FogGroupByName', 'Get-FogGroups', 
               'Get-FogHost', 'Get-FogHostAssociatedSnapins', 'Get-FogHostGroup', 
               'Get-FogHostMacs', 'Get-FogHostPendingMacs', 'Get-FogHosts', 
               'Get-FogImages', 'Get-FogInventory', 'Get-FogLog', 
               'Get-FogMacAddresses', 'Get-FogModules', 'Get-FogObject', 
               'Get-FogSecsSinceEpoch', 'Get-FogServerSettings', 
               'Get-FogServerSettingsFile', 'Get-FogSnapinAssociations', 
               'Get-FogSnapins', 'Get-LastImageTime', 'Install-FogService', 
               'Invoke-FogApi', 'New-FogHost', 'New-FogObject', 'Receive-FogImage', 
               'Remove-FogObject', 'Remove-UsbMac', 'Repair-FogSnapinAssociations', 
               'Reset-HostEncryption', 'Resolve-HostID', 'Send-FogImage', 
               'Set-FogInventory', 'Set-FogServerSettings', 
               'Set-FogServerSettingsFileSecurity', 'Set-FogSnapins', 
               'Start-FogSnapin', 'Start-FogSnapins', 'Update-FogObject'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = 'Remove-FogMac', 'Get-FogAssociatedSnapins', 'Get-FogHostSnapins', 
               'Get-FogHostSnapinAssociations', 'Get-FogGroup', 'Get-MacsForHost', 
               'Get-FogMacs', 'Add-FogHost', 'Add-FogObject', 'Save-FogImage', 
               'Invoke-FogImageCapture', 'Capture-FogImage', 'Pull-FogImage', 
               'Push-FogImage', 'Deploy-FogImage', 'Add-FogSnapins', 'Set-FogObject'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    #Title of this module
    Title = 'FogApi'

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'fog','fogapi','imaging','provisioning','fogproject'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/FOGProject/fog-community-scripts/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/darksidemilk/FogApi'

        # A URL to an icon representing this module.
        IconUri = 'https://fogproject.org/images/favicon.ico'

        # ReleaseNotes of this module
        ReleaseNotes = '
# 2311.6.4

	typo bug fix there was a stray extra character. Also added switch for Set-FogSnapins called -repairBeforeAdd to allow running the repair before attempting to add. Also added in more try catch logic to set-fogsnapins. Also cleaned up release notes in manifest to just include the latest release to allow for faster import of module'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://fogapi.readthedocs.io/en/latest/'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

