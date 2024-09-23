# Choco Package Template

This is the template for creating the chocolatey package with the build-choco.ps1 script at the root of this repo. 
[build-choco.ps1](https://github.com/darksidemilk/FogApi/blob/master/build-choco.ps1) is run after running the  [build.ps1](https://github.com/darksidemilk/FogApi/blob/master/build.ps1) is run and typically after publishing to the powershell gallery so the same nuspec published to the psgallery is used for the choco package (with some chocolatey specific alterations)
The nuspec found here is a general template for what is built, it isn't actually used in the build script at this time, though it may later as things evolve, it is stored here for reference for now. 

The PSGetModuleInfo.xml file in the zip file (downloaded from each release) are generated at save/install time by PowershellGet/PSResourceGet and are what are required for a module to show in the `Get-InstalledModule` and `Get-InstalledPSResource -scope allusers` commands.

You can find the nupkg files that are published to the PSGallery and to Chocolatey as well as zips of the built module and the built module including the PSGetModuleInfo.xml (with the Powershell 7 Program Files path specified as the install location) in the assets of each release (from version 2409.9.16 onwards + version 2408.9.3 which is the first version published in the chocolatey community repository) - [Releases](https://github.com/darksidemilk/FogApi/releases)