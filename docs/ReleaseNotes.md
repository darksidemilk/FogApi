
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

	updated aliases for receive-image to remove unapproved verb warnings. Updated path to api-settings.json file to work with other operating systems universally by using the home variable in a user's context. Fixed issues with set-fogserversettings so it flows better when you give some but not all parameters. Updated readme and about to include set-fogserversettings instructions more explicitly

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

	Fix add-foghostmac and various other functions that were using 1 and 0 instead of the proper string form of '1' and '0' so that the database handles the input properly. Fixed Start-FogSnapins so it doesn't stop all pending tasks for all hosts, it will only cancel any existing snapin tasks for the specified host before starting the new tasks

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

# 2002.2.1.2

	Description in manifest was too long

# 2002.2.1.1

	Updated documentation on most functions, all have at least some basic info. Also linked all documentation to https://fogapi.readthedocs.io/en/latest/ for online versions

# 2002.2.0.8

	general updates and bug fixes

# 2002.2.0.7

	Test build

# 2002.2.0.6

	Test build

# 2002.2.0.5

    Test build

# 2002.2.0.4
    
    Test build

# 1904.0.0.1
        
    CF-249 #comment fixed add-fogmac property within the function and incrementing the version to match release time

# 1903.0.0.23

    Added functions for reseting host encryption as well as adding, approving, and removing macs from hosts

# 1903.0.0.22

    Move from dev to production

# 1903.0.0.21

    update documentation

# 1903.0.0.20

    dont addition on random variable create a list

# 1903.0.0.19

    update get settings with same new paths silly

# 1903.0.0.18

    force the copy

# 1903.0.0.17

    change where settings file is stored to an appdata folder of the current user

# 1903.0.0.16

    CF-214 #comment updated remove-usbmac to utilize internal functions better and made it more universal, may want to later update it to remove all matching associations of the list, but would also need a function for getting the mac list of the host it is connected to when it is the primary which sounds cumbersome at the moment

# 1903.0.0.15

    Updated documentation for each function and moved the dynamic param functions to be private functions as they dont need to be visible in the user interface

# 1903.0.0.14

    CF-223 #comment use internal commands more

# 1903.0.0.13

    CF-223 #comment use internal commands more

# 1903.0.0.12

    dont try to add snapins that are already there

# 1903.0.0.11

    CF-223 #comment updated set-fogsnapins to use internal new-fogobject function and had it only attempt to set snapins that actually exist

# 1903.0.0.10

    CF-223 #comment updated set-fogsnapins to use internal new-fogobject function and had it only attempt to set snapins that actually exist

# 1903.0.0.9

    CF-223 #comment made setting list of fogsnapins more universal and not reference object it doesnt need to

# 1903.0.0.8

    CF-223 #comment made setting list of fogsnapins more universal and not reference object it doesnt need to

# 1903.0.0.7

    CF-223 #comment fix uuid get in getfoghost

# 1903.0.0.6

    CF-223 #comment fix uuid get and set for when uuid isnt correct in first spot

# 1903.0.0.5

    CF-129 #comment updated fogapi syntax issues fixes

# 1903.0.0.4

    CF-206 #comment quick syntax updates on fogapi dev module

# 1903.0.0.3

    CF-205 #comment updated fogapi dev module with functions for snapins

# 1903.0.0.2

    CF-204 #comment updated various functions to utilize new structure

# 1903.0.0.1

    CF-204 #comment updated fogapi module to new module structure

# 1902.0.0.3

    CF-218 #comment default invoke-api to use GET method

# 1902.0.0.2

    CF-218 #comment need to have published the dev fogapi module without dev prefix

# 1902.0.0.1

    CF-124 #comment added get-foglog function for easier opening of a dynamic fog log when debugging provisioning and imaging issues

# 1.8.1.6

    testing fix for update error looks like the wrong dynamic parameter was being referenced where the uri was being built

# 1.8.1.5

    CF-120 #comment adding fogapi dev module to repo

# 1.8.1.4

    fix possible exit

# 1.8.1.3

    use spacebar and use ea 0 on get-service check for install-fogservice

# 1.8.1.2

    finish end block on install-fogservice

# 1.8.1.1

    updated install-fogservice to try using the smart installer if the msi doesn	 work

# 1.8.0.5

    fixes to settings setter and remove double slashes

# 1.8.0.4

    fixes to settings setter and remove double slashes

# 1.8.0.3

    fixes to settings setter

# 1.8.0.2

    fixes to settings setter

# 1.8.0.1

    updated settings setter and getter to store settings json in fog service folder

# 1.7.1.1

    try catch block to attempt iwr when irm fails

# 1.7.0.5

    update update function to allow specifying uri path manually

# 1.7.0.4

    update update function to allow specifying uri path manually

# 1.7
    
    Fixed parantheses typo in get-fogobject and signing issue

# 1.5
    
    Added dynamic parameters and added get-fogserversettings and set-fogserversettings to allow for setting the api keys and server name in the shell
    One known issue with the dynamic parameters is that they currently are not working as expected with positions they have to be named. i.e. you have to say get-fogobject -type object -coreObject host not Get-FogObject object host like I wanted
    The auto complete works for positional parameters but the function doesn''t seem to think there''s a vaule for the parameter.

# 1.3

    added better description and links, fixed new-fogobject to not require id for all POST api calls as there is no id yet for new items.

# 1.2
    
    Initial Release, allow for easy manipulation of FOG server data with powershell objects

