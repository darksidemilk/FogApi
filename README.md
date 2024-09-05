# Overview

[![Test Build](https://github.com/darksidemilk/FogApi/actions/workflows/build-test.yml/badge.svg?branch=master)](https://github.com/darksidemilk/FogApi/actions/workflows/build-test.yml)

[![Tag, Release, and Publish to PSGallery and Chocolatey Community Repo](https://github.com/darksidemilk/FogApi/actions/workflows/tag-and-release.yml/badge.svg)](https://github.com/darksidemilk/FogApi/actions/workflows/tag-and-release.yml)

This is a powershell module to make using the Fog Project API even easier.
FOG is an opensource tool for imaging comptuters, this module uses the API on your internal fog server to perform almost any operation you can do in the GUI of Fog and provides you with the ability to extend things further.
It can be used to create more automation or to simply have a command line method of controlling fog operations.
For more information about FOG see

* https://FOGProject.org
* https://docs.fogproject.org
* https://github.com/FOGProject
* https://github.com/FOGProject/fogproject

Docs can be found at https://fogapi.readthedocs.io/en/latest/

## Notes about its new home and future structuring

This module used to be housed at https://github.com/FOGProject/fog-community-scripts/tree/master/PowershellModules/FogApi but has been now moved to its own repo to follow best practicies for powershell modules. Overtime I hope to add pester tests and use other powershell build tools like invoke-build or psake. For now there's a simpler build.ps1 script for combinging the functions into a single module and generating/building/compiling the documentation (using the platyps module). You only need to use the build.ps1 if you want to manually install it instead of using the simpler `Install-Module fogapi` to install it from the powershell gallery.

# Versioning

The versioning of this module follows this pattern

`{Year|Month}.{Major Version}.{Revision #}`

## Year/Month

This versioning shows you first the Year and month this version of the module was published, giving you an idea of when it was last updated.
i.e. 2208 would be august 2022.

## Major

The Major version follows the typical major versioning where any major changes will increment this version number, especially possible breaking changes or structural changes, etc.

## Minor/Revision

Any time I publish a new version that isn't a major change I'll increment the revision. This may also be incremented for each build test and increment by more than one for each published version

# Installation

The module can be installed via PowershellGet, PSResourceGet, Chocolatey, or Manually

## Installation Methods
    
To install this module you need at least powershell v3, it was originally created with 5.1,
but now for BEST EXPERIENCE use Powershell Core 7+ to be able to use tab completion when running Fog 1.6

To Install this module follow these steps

### Install from PSgallery

* Easiest method: Install from PSGallery https://www.powershellgallery.com/packages/FogApi with powershellget or PSResourceGet
    * `Install-Module -name FogApi -Scope AllUsers`
    * `Install-PSResource -Name FogApi -scope -Scope AllUsers`
* updating is then as easy as
    * `Update-Module -name FogApi`
    * `Update-PSResource -Name FogApi`

### Install with Chocolatey

If you have chocolatey package manager, you can use the published package that manually installs the module the same way the PSGet managers do.
https://community.chocolatey.org/packages/FogApi
See https://chocolatey.org for more information on chocolatey package manager

* Install with chocolatey (will install the module by copying the built version to the powershell core and windows powershell paths, will remove any existing versions)
    * `choco install fogapi -y`
* Upgrading is as easy as (note that you can also use this same command for a new install)
    * `choco upgrade fogapi -y`

## Manual Installation

### Use assets from the release

* Use Chocolatey, PackageManagement, Nuget or what have you to install the *chocolatey.nupkg or *.psgallery.nupkg file from the release assets
* Extract the *builtModule.zip from the release and run `import-module` on the resulting folder for a portable installation. You can also extract to the paths outlined below in the manual build install steps for a more system wide install

### Manually build the module

* Manual Method:
* download the zip of this repo and extract it (or use git clone)
    * Or clone the repo using your favorite git tool, you just need the FogApi Folder this readme is in
* Run the build.ps1 script
* Copy the built module folder (.\_module_build) into...
    * For Windows Powershell v3-v5.1
        * C:\Program Files\WindowsPowershell\Modules\FogApi
    * For Powershell Core (pwsh) on Windows v7+
        * C:\Program Files\PowerShell\Modules\FogApi
    * For Linux Powershell Core (pwsh) v7+
        * /usr/local/share/powershell/Modules/FogApi
    * For Mac Powershell Core (pwsh) v7+ (untested)
        * /usr/local/share/powershell/Modules/FogApi
            * I haven't tested this on a mac, the module folder may be somewhere else
            this is based on where it is in other powershell core installs
* Open powershell (as admin recommended)
* Run `Import-Module FogApi`

The module is now installed. 

# Using The Module

You can use `Set-FogServerSettings` to set your fogserver hostname and api keys.

The first time you try to run a command the settings.json file will automatically open if it isn't already configured
in notepad on windows, nano on linux, or TextEdit on Mac

You can also open the settings.json file and edit it manually before running your first command, but it's best to use the `Set-FogServerSettings -interactive` function and switch for first time setup.
The default settings in `settings.json` are explanations of where to find the proper settings since json can't have comments

Once the settings are set you can have a jolly good time utilzing the fog documentation
found here https://news.fogproject.org/simplified-api-documentation/ that was used to model the parameters

i.e.

`Get-FogObject` has a type param that validates to `object, objectactivetasktype, and search` as those are the options given in the documentation.
Each of those types validates (which means autocompletion) to the core types listed in the documentation.
So if you typed in `Get-FogObject -Type object -Object h` and then started hitting tab, it would loop through the possible core objects you can get from the api that start with `h` such as history, host, etc.

Unless you filter a GET with a json body it will return all the results into a powershell object. 
That object is easy to work with to create other commands. Note: Full Pipeline support will come at a later time
i.e.

```
hosts = Get-FogObject -Type Object -CoreObject Host # calls GET on {your-fog-server}/fog/host to list all hosts
```

Now you can search all your hosts for the one or ones you are looking for with powershell
maybe you want to find all the hosts with ''IT'' in the name  (note `?` is an alias for `Where-Object`)

```
$ITHosts = $hosts.data | ? name -match ''IT'';
```

Now maybe you want to change the image all of these computers use to one named ''''IT-Image''''
You can edit the object in powershell with a foreach-object (`%` is an alias for `foreach-object`)

```
#get the id of the image by getting all images and finding the one with the IT-image name
$image = Get-FogImages | ? name -eq "IT-image"
$updatedITHosts = $ITHosts | % { $_.imageid = $image.id}
```

Then you need to convert that object to json and pass each object into one api call at a time. 
Which sounds complicated, but it's not, it's as easy as

```
$updatedITHosts | % {
    Update-FogObject -Type object -CoreObject host -objectID $_.id -jsonData ($_ | ConvertTo-Json);
}
```

This is just one small example of the limitless things you can do with the api and powershell objects.
There are also many ''helper'' functions that make various operations easier.
i.e. Maybe you want to create a host and deploy that "IT-image" image to it.

```
#create the host
New-FogHost -name "test-host" -macs "01:23:45:67:89:00"

#add the image to the host
$foghost = get-foghost -hostname "test-host";
$image = Get-FogImages | ? name -eq "IT-image"
$foghost.imageid = $image.id;
$jsonData = $fogHost | ConvertTo-Json;
Update-FogObject -Type object -CoreObject host -objectID $foghost.id -jsonData jsonData;

#start the image task on the host now
get-foghost -hostname "test-host" | send-fogimage
```

```
#alternatively, schedule the image for later, like 10pm tomorrow
get-foghost -hostname "test-host" | send-fogimage -StartAtTime (Get-Date 10pm).AddDays(1)
```

## Additional info

See also the fogforum thread for the module https://forums.fogproject.org/topic/12026/powershell-api-module/2
