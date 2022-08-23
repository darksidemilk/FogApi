# Overview

This is a powershell module to make using the Fog Project API even easier.
FOG is an opensource tool for imaging comptuters, this module uses the API on your internal fog server to perform almost any operation. It can be used to create more automation or to simply have a command line method of controlling fog operations.

Docs can be found at https://fogapi.readthedocs.io/en/latest/

## Notes about its new home and future structuring

This module used to be housed at https://github.com/FOGProject/fog-community-scripts/tree/master/PowershellModules/FogApi but has been now moved to its own repo to follow best practicies for powershell modules. Overtime I hope to add pester tests and use other powershell build tools like invoke-build or psake. For now there's a simpler build.ps1 script for combinging the functions into a single module and generating/building/compiling the documentation (using the platyps module). You only need to use the build.ps1 if you want to manually install it instead of using the simpler `Install-Module fogapi` to install it from the powershell gallery.

# Versioning

The versioning of this module follows this pattern

`{Year|Month}.{Major Version}.{Revision #}`

## Year/Month

This versioning shows you first the Year and month this version of the module was published, giving you an idea of when it was last updated.

## Major

The Major version follows the typical major versioning where any major changes will increment this version number, especially possible breaking changes or structural changes, etc.

## Minor/Revision

Any time I publish a new version that isn't a major change I'll increment the revision. This may also be incremented for each build test and increment by more than one for each published version

# Installation

All completed/tested/stable releases of this module will be published to powershell gallery. I don't currently have any plans to use github releases 

## Requirements

To install this module you need at least powershell v3, was created with 5.1 and intended to be cross platform compatible with powershell v6 and v7

To Install this module follow these steps...

## Install From PSGallery

* Easiest method: Install from PSGallery https://www.powershellgallery.com/packages/FogApi via a powershell console with the command `Install-Module -name fogApi` 

## Manual Installation

* Manual Method:
* download the zip of this repo and extract it
    * Or clone the repo using your favorite git tool, you just need the FogApi Folder this readme is in
* Run the build.ps1 script
* Copy the built module folder (C:\moduleBuild\fogAPI) into...
    * For Windows Powershell v3-v5.1
        * C:\Program Files\WindowsPowershell\Modules
    * For Windows Powershell v6+
        * C:\Program Files\PowerShell\6-preview\Modules
            * 6-Preview may need to be replaced with whatever current version you have installed
    * For Linux Powershell v6+
        * /opt/microsoft/powershell/6.1.0-preview.2/Modules
            * 6.1.0-preview.2 may need to be replaced with whatever current version you have installed
    * For Mac Powershell v6+ (untested)
        * /usr/local/microsoft/powershell/6.x/Modules
            * 6.x should be replaced with whatever most current version you are using
            * I haven't tested this on a mac, the module folder may be somewhere else
            this is based on where it is in other powershell 6 installs
* Open a powershell command prompt (I always run as admin, unsure if it's required)
* Run `Import-Module FogApi`

The module is now installed. 

# Using The Module

The first time you try to run a command the settings.json file will automatically open
in notepad on windows, nano on linux, or TextEdit on Mac
You can also open the settings.json file and edit it manually before running your first command.
The default settings are explanations of where to find the proper settings since json can't have comments

Once the settings are set you can have a jolly good time utilzing the fog documentation 
found here https://news.fogproject.org/simplified-api-documentation/ that was used to model the parameters

i.e.

Get-FogObject has a type param that validates to object, objectactivetasktype, and search as those are the options given in the documentation.
Each of those types validates (which means autocompletion) to the core types listed in the documentation.
So if you typed in `Get-FogObject -Type object -Object  h` and then started hitting tab, it would loop through the possible core objects you can get from the api that start with 'h' such as history, host, etc.

Unless you filter a get with a json body it will return all the results into a powershell object. That object is easy to work with to create other commands. Note: Full Pipeline support will come at a later time 
 i.e.

 `$hosts = Get-FogObject -Type Object -CoreObject Host `# calls get on http://fog-server/fog/host to list all hosts
 Now you can search all your hosts for the one or ones you're looking for with powershell
 maybe you want to find all the hosts with 'IT' in the name  (note '?' is an alias for Where-Object)
`$ITHosts = $hosts.hosts | ? name -match 'IT';`

Now maybe you want to change the image all of these computers use to one named 'IT-Image'
You can edit the object in powershell with a foreach-object ('%' is an alias for foreach-object)
`$updatedITHosts = $ITHosts | % { $_.imagename = 'IT-image'}`

Then you need to convert that object to json and pass each object into one api call at a time. Which sounds complicated, but it's not, it's as easy as
```
$updateITHosts | % { 
    $jsonData = $_ | ConvertTo-Json;
    Update-FogObject -Type object -CoreObject host -objectID $_.id -jsonData $jsonData;
    #successful result of updated objects properties 
    #or any error messages will output to screen for each object
} 
```

This is just one small example of the limitless things you can do with the api and powershell objects.

see also the fogforum thread for the module https://forums.fogproject.org/topic/12026/powershell-api-module/2 
