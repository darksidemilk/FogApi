#
# Module manifest for module 'FogApi'
#
# Generated by: JJ Fullmer
#
# Generated on: 3/29/2023
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'FogApi.psm1'

# Version number of this module.
ModuleVersion = '2302.5.32'

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
               'Get-FogAssociatedSnapins', 'Get-FogGroupAssociations', 
               'Get-FogGroupByName', 'Get-FogGroups', 'Get-FogHost', 
               'Get-FogHostGroup', 'Get-FogHostMacs', 'Get-FogHostPendingMacs', 
               'Get-FogHosts', 'Get-FogImages', 'Get-FogInventory', 'Get-FogLog', 
               'Get-FogMacAddresses', 'Get-FogModules', 'Get-FogObject', 
               'Get-FogSecsSinceEpoch', 'Get-FogServerSettings', 
               'Get-FogServerSettingsFile', 'Get-FogSnapins', 'Get-LastImageTime', 
               'Install-FogService', 'Invoke-FogApi', 'New-FogHost', 'New-FogObject', 
               'Receive-FogImage', 'Remove-FogObject', 'Remove-UsbMac', 
               'Reset-HostEncryption', 'Resolve-HostID', 'Send-FogImage', 
               'Set-FogInventory', 'Set-FogServerSettings', 
               'Set-FogServerSettingsFileSecurity', 'Set-FogSnapins', 
               'Start-FogSnapin', 'Start-FogSnapins', 'Update-FogObject'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = 'Remove-FogMac', 'Add-FogSnapins', 'Set-FogObject', 'Add-FogHost', 
               'Get-FogGroup', 'Get-MacsForHost', 'Get-FogMacs', 'Add-FogObject'

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
# 2302.5.32

	Make set security of settings file have less output. Added example and notes to update-fogobject concerning host updates where name isn''t changing. Also added condition for a future change to location of fog log in windows

# 2302.5.31

	general updates and bug fixes

# 2302.5.30

	general updates and bug fixes

# 2302.5.29

	general updates and bug fixes

# 2302.5.28

	general updates and bug fixes

# 2302.5.27

	general updates and bug fixes

# 2302.5.26

	add default value to input validator to assume current host when none is given

# 2302.5.25

	add input validation to foghostmac functions via new resolve-hostid command that will get the hostid for foghost objects, or a hostname or an actual int. ALso validates that the id exists on a valid host

# 2302.5.24

	fix interactive server settings setter, it wasn''t updating the parent object variable after grabbing the input

# 2302.5.23

	Add-FogHostMac - add a check for existing mac association and allow a -forceUpdate switch to change what host a mac is associated to

# 2302.5.22

	add a check for existing mac association

# 2302.5.21

	add a check for existing mac association

# 2302.5.20

	general updates and bug fixes


# 2302.5.16

	general updates and bug fixes

# 2302.5.15

	Not using alias urls for create and edit

# 2302.5.14

	don''t attempt to convert body to string

# 2302.5.13

	general updates and bug fixes

# 2302.5.12

	general updates and bug fixes

# 2302.5.11

	general updates and bug fixes

# 2302.5.10

	reverted get-foghostgroup to not use find-fogobject, updated find-fogobject output for universal search. Added a null check to add-resultdata in cases where no result was found in get-fogobject. General fixes for fog 1.6 compatibility

# 2302.5.9

	testing find-fogobject uni search result

# 2302.5.8

	revert get-foghostgroup to get-fogobject method, find-fogobject needs work

# 2302.5.7

	missed a .data in get-foghostgroup

# 2302.5.6

	get-foghost quick fix for having all fields

# 2302.5.5

	testing get-foghost quick fix

# 2302.5.4

	Make sure get-foghost returns the full host field output after finding the host from the limited field version result of all hosts

# 2302.5.3

	Make sure get-foghost returns the full host field output after finding the host from the limited field version result of all hosts

# 2302.5.2

	removed outdated release notes to meet the 10000 character limit

# 2302.5.1

	BREAKING CHANGES. While I did try to keep things as compatible as possible, there is a chance of a breaking change.
    In the interest of moving to fog 1.6 we are changing the output of get-fogobject and the new find-fogobject to always have all the resulting objects in a .data
    property instead of a property named for the bject type (i.e. hosts, snapins, tasks, etc). This simplifies the structure and makes the api module
     compatible with both 1.5.x and 1.6+ versions. If you are using fog 1.5.x the old property names will be kept so if you have existing scripts that reference the
     result properties like .hosts, .snapins, etc they''ll need to be changed to use .data to work with fog 1.6
    I changed the output of all the helper functions that utilize Get-FogObject (i.e. Get-FogHosts, Get-FogImages, Get-FogSnapins) to use the new data property in their return values so they should work out of the box with fog 1.6 anywhere they''re being used.
    Additionally, I also added a Find-FogObject function that has working search functionality. For fog 1.5.x you can search in specific object types.
    i.e. Find-FogObject -type search -coreObject host -stringtosearch ''computerName'' will find all fog host objects that match ''comptuerName'' in any field values.
    You could also search for hosts with a given mac, or snapins of a given name, etc.
    For fog 1.6 you can omit -coreObject and should be able to do a universal search of all fog fields
     The helper function Get-FogGroupByName now uses find-fogobject for a faster search by name. Additional helpers like Find-FogHost, Find-FogSnapin may be added
    in the future.

# 2209.4.7

	general updates and bug fixes

# 2209.4.6

	general updates and bug fixes

# 2209.4.5

	make aliases with unapproved verbs and use approved verbs for main name of deploy and capture image functions. So the main names are Send-FogImage to deploy an image to a host and Receive-FogImage will capture an image from a host. This will get rid of the warning on import

# 2209.4.4

	make aliases with unapproved verbs and use approved verbs for main name of deploy and capture image functions. So the main names are Send-FogImage to deploy an image to a host and Receive-FogImage will capture an image from a host. This will get rid of the warning on import

# 2209.4.3

	make aliases with unapproved verbs and use approved verbs for main name of deploy and capture image functions. So the main names are Send-FogImage to deploy an image to a host and Receive-FogImage will capture an image from a host. This will get rid of the warning on import

# 2209.4.2

	general updates and bug fixes

# 2209.4.1

	increment version

# 2208.3.6

	updated aliases for receive-image to remove unapproved verb warnings. Updated path to api-settings.json file to work with other operating systems universally by using the home variable in a user''s context. Fixed issues with set-fogserversettings so it flows better when you give some but not all parameters. Updated readme and about to include set-fogserversettings instructions more explicitly

# 2208.3.5

	general updates and bug fixes

# 2208.3.4

	general updates and bug fixes

# 2208.3.3

	minor syntax issue fixes for deploy and capture, and added missing example description

# 2208.3.2

	general updates and bug fixes

# 2208.3.1

	- Added serialnumber option for Get-FogHost - Added faster processing for Get-FogHost -hostid so it gets it directly rather than getting all hosts and then searching- Added Get-LastImageTime function to get a hosts last image history log entry, can search for the host by serialnumber (prompts for barcode input by default)

# 2208.3.0

	adding deploy and capture functions, using ciminstance instead of wmi for get-foginventory for powershell core compatibility, adding start-fogsnapin single snapin functionality. Also added get-fogimages helper function to get all fog images that currently exist in the fog server. Closes #2 Closes #4

# 2103.2.12

	updated set-fogsnapin help

# 2103.2.11

    Updated aliases to export in manifest to include all created aliases

# 2103.2.10

	Fixed Get-FogGroups and added a simple new-foghost function

# 2004.2.2.7

	Fix add-foghostmac and various other functions that were using 1 and 0 instead of the proper string form of ''1'' and ''0'' so that the database handles the input properly. Fixed Start-FogSnapins so it doesn''t stop all pending tasks for all hosts, it will only cancel any existing snapin tasks for the specified host before starting the new tasks

# 2004.2.2.6

	general updates and bug fixes

# 2004.2.2.5

	general updates and bug fixes

# 2004.2.2.4

	Changed get-macsforhost to Get-FoghostMacs. Added output if get-foghost returns multiple hosts

# 2004.2.2.3

	fix release note formatting error

# 2004.2.2.2

	added try catch for ciminstance for powershell 7 compatibility in windows when getting the current foghost without params

# 2004.2.2.1

    * Mainly a bug fix release for issues with pending mac handling.Ended up adding some extra helper functions along the way
    * Added more get functions for ease of use including
        - Get-FogGroupAssociations
        - Get-FogGroupByName
        - Get-FogGroups
        - Get-FogHostGroup (replaces Get-FogGroup, but kept Get-FogGroup as an alias as to not break anyones scripts)
        - Get-FogMacAddresses (has alias of Get-FogMacs)
        - Get-MacsForHost
    * Fixed Approve-FogPendingMac so it makes a given mac not pending instead of keeping it pending
    * Fixed Get-PendingMacsForHost so it uses less pipeline and more separate commands that was causing it to return all pending macs in some cases, rather than just for a given host
    * Added hostID param to get-foghost so you can get a host from the internal hostID if you already have that

'

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

