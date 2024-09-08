# Release Notes

## 9.x

### 2409.9.6

	Fix choco template issue of typo of folder name sources vs files


### 2409.9.5

	Updated and unified various docs, added icon packaging with best practicies for chocolatey and psgallery. Updated chocolatey packaging and build functions.


### 2409.9.4

	Adding Chocolatey package and updates to auto adding various assets to each release. 
	Also updated some manifest things.
	No Code changes, really just a maintenance release

### 2408.9.3

	Fix missing release note and try using fregante/setup-git-user@v2.0.2 to ensure publish build and commit gets pushed

### 2408.9.2

	# 2408.9.2

	Release Commit of Major Changes (some changes in other commits)
	- Handled Auto add aliases on build #9 so added aliases are available to users.
	- Implemented Add foghost name tab completion #8
	- Added github actions for testing build and releasing versions
	- Fixed issue with getting fog inventory in 1.6
	- Implemented #16 for getting and setting fog global settings in fog 1.6
	- Implemented #14 for getting the fog version
	- Implemented #13 for invoking wol task for a host
	- Added basic pipeline functionality for foghost objects in all applicable functions.
	- Made it possible to send multiple specified snapins in a single start-fogsnapin call
	- Added tab completion of server specific host names and snapin names in various functions like get-foghost, start-fogsnapin. set-fogsnapins, remove-usbmac
	- removed advanced function begin/end blocks where they weren't being used as such, kept things in process block
	- implemented Add https option to fog server settings #15 by making it so you can put http://fogserver or https://fogserver or fogserver as the fogserver property in settings to implement that change with minimal issues with existing setting configs. Added an enable-FogApiHTTPS funcction as well as a disable to easily enable that.
	- Implemented Add function for attempting to set windows machine to boot to pxe from within windows #17

### 2408.9.1

	resolves Auto add aliases on build #9 
	
### 2408.9.0

	Major version doc updates, added many new functions and implemented some pipeline functionality

## 6.x

### 2408.6.15

	Implemented geting and setting fog settings in fog 1.6. Setting names support tab complete of names


### 2408.6.14

	Made basic implementation for getting all fog settings or individual setting. Dynamic Tab completer not quite working, may put in a static list or a list that gets updated on import?
	
### 2408.6.13

	general updates and bug fixes
### 2408.6.12

	general updates and bug fixes


### 2408.6.11

	Fix get-fogversion if before version 1.6 or if error on info page

### 2408.6.9

	Created Get-FogVersion and implmented check for 1.6 version
	so correct dynamic parameters are used for 1.5.x vs 1.6
	Also added a separate build test script for running a build test
	on each push.

### 2311.6.4

	typo bug fix there was a stray extra character. Also added switch for Set-FogSnapins called -repairBeforeAdd to allow running the repair before attempting to add. Also added in more try catch logic to set-fogsnapins. Also cleaned up release notes in manifest to just include the latest release to allow for faster import of module


### 2310.6.3

	fixed missing aliases to export

### 2310.6.2

	fixed duplicate release notes in manifest

### 2310.6.1

	Added new snapin association functions for removing invalid entries and preventing any existing invalid associations from causing an error

## 5.x

### 2304.5.41

	Fix build versioning

### 2302.5.40

	Fix Test-path negation test

### 2302.5.39

	fix test-path error

### 2302.5.38

	general updates and bug fixes

### 2302.5.37

	Fix Test-path negation test

### 2302.5.36

	Fix Test-path negation test

### 2302.5.35

	general updates and bug fixes

### 2302.5.34

	general updates and bug fixes

### 2302.5.33

	added -exactnames switch to set-fogsnapins to allow match or eq matching of given snapin names

### 2302.5.32

	Make set security of settings file have less output. Added example and notes to update-fogobject concerning host updates where name isn't changing. Also added condition for a future change to location of fog log in windows

### 2302.5.31

	general updates and bug fixes

### 2302.5.30

	general updates and bug fixes

### 2302.5.29

	general updates and bug fixes

### 2302.5.28

	general updates and bug fixes

### 2302.5.27

	general updates and bug fixes

### 2302.5.26

	add default value to input validator to assume current host when none is given

### 2302.5.25

	add input validation to foghostmac functions via new resolve-hostid command that will get the hostid for foghost objects, or a hostname or an actual int. ALso validates that the id exists on a valid host

### 2302.5.24

	fix interactive server settings setter, it wasn't updating the parent object variable after grabbing the input

### 2302.5.23

	Add-FogHostMac - add a check for existing mac association and allow a -forceUpdate switch to change what host a mac is associated to

### 2302.5.22

	add a check for existing mac association

### 2302.5.21

	add a check for existing mac association

### 2302.5.20

	general updates and bug fixes


### 2302.5.16

	general updates and bug fixes

### 2302.5.15

	Not using alias urls for create and edit

### 2302.5.14

	don't attempt to convert body to string

### 2302.5.13

	general updates and bug fixes

### 2302.5.12

	general updates and bug fixes

### 2302.5.11

	general updates and bug fixes

### 2302.5.10

	reverted get-foghostgroup to not use find-fogobject, updated find-fogobject output for universal search. Added a null check to add-resultdata in cases where no result was found in get-fogobject. General fixes for fog 1.6 compatibility

### 2302.5.9

	testing find-fogobject uni search result

### 2302.5.8

	revert get-foghostgroup to get-fogobject method, find-fogobject needs work

### 2302.5.7

	missed a .data in get-foghostgroup

### 2302.5.6

	get-foghost quick fix for having all fields

### 2302.5.5

	testing get-foghost quick fix

### 2302.5.4

	Make sure get-foghost returns the full host field output after finding the host from the limited field version result of all hosts

### 2302.5.3

	Make sure get-foghost returns the full host field output after finding the host from the limited field version result of all hosts

### 2302.5.2

	removed outdated release notes to meet the 10000 character limit

### 2302.5.1

	BREAKING CHANGES. While I did try to keep things as compatible as possible, there is a chance of a breaking change.
    In the interest of moving to fog 1.6 we are changing the output of get-fogobject and the new find-fogobject to always have all the resulting objects in a .data
    property instead of a property named for the bject type (i.e. hosts, snapins, tasks, etc). This simplifies the structure and makes the api module
     compatible with both 1.5.x and 1.6+ versions. If you are using fog 1.5.x the old property names will be kept so if you have existing scripts that reference the
     result properties like .hosts, .snapins, etc they'll need to be changed to use .data to work with fog 1.6
    I changed the output of all the helper functions that utilize Get-FogObject (i.e. Get-FogHosts, Get-FogImages, Get-FogSnapins) to use the new data property in their return values so they should work out of the box with fog 1.6 anywhere they're being used.
    Additionally, I also added a Find-FogObject function that has working search functionality. For fog 1.5.x you can search in specific object types.
    i.e. Find-FogObject -type search -coreObject host -stringtosearch 'computerName' will find all fog host objects that match 'comptuerName' in any field values.
    You could also search for hosts with a given mac, or snapins of a given name, etc.
    For fog 1.6 you can omit -coreObject and should be able to do a universal search of all fog fields
     The helper function Get-FogGroupByName now uses find-fogobject for a faster search by name. Additional helpers like Find-FogHost, Find-FogSnapin may be added
    in the future.

## 4.x

### 2209.4.7

	general updates and bug fixes

### 2209.4.6

	general updates and bug fixes

### 2209.4.5

	make aliases with unapproved verbs and use approved verbs for main name of deploy and capture image functions. So the main names are Send-FogImage to deploy an image to a host and Receive-FogImage will capture an image from a host. This will get rid of the warning on import

### 2209.4.4

	make aliases with unapproved verbs and use approved verbs for main name of deploy and capture image functions. So the main names are Send-FogImage to deploy an image to a host and Receive-FogImage will capture an image from a host. This will get rid of the warning on import

### 2209.4.3

	make aliases with unapproved verbs and use approved verbs for main name of deploy and capture image functions. So the main names are Send-FogImage to deploy an image to a host and Receive-FogImage will capture an image from a host. This will get rid of the warning on import

### 2209.4.2

	general updates and bug fixes

### 2209.4.1

	increment version

## 3.x

### 2208.3.6

	updated aliases for receive-image to remove unapproved verb warnings. Updated path to api-settings.json file to work with other operating systems universally by using the home variable in a user's context. Fixed issues with set-fogserversettings so it flows better when you give some but not all parameters. Updated readme and about to include set-fogserversettings instructions more explicitly

### 2208.3.5

	general updates and bug fixes

### 2208.3.4

	general updates and bug fixes

### 2208.3.3

	minor syntax issue fixes for deploy and capture, and added missing example description

### 2208.3.2

	general updates and bug fixes

### 2208.3.1

	- Added serialnumber option for Get-FogHost - Added faster processing for Get-FogHost -hostid so it gets it directly rather than getting all hosts and then searching- Added Get-LastImageTime function to get a hosts last image history log entry, can search for the host by serialnumber (prompts for barcode input by default)

### 2208.3.0

	adding deploy and capture functions, using ciminstance instead of wmi for get-foginventory for powershell core compatibility, adding start-fogsnapin single snapin functionality. Also added get-fogimages helper function to get all fog images that currently exist in the fog server. Closes #2 Closes #4

## 2.x

### 2103.2.12

	updated set-fogsnapin help

### 2103.2.11

    Updated aliases to export in manifest to include all created aliases

### 2103.2.10

	Fixed Get-FogGroups and added a simple new-foghost function

### 2004.2.2.7

	Fix add-foghostmac and various other functions that were using 1 and 0 instead of the proper string form of '1' and '0' so that the database handles the input properly. Fixed Start-FogSnapins so it doesn't stop all pending tasks for all hosts, it will only cancel any existing snapin tasks for the specified host before starting the new tasks

### 2004.2.2.6

	general updates and bug fixes

### 2004.2.2.5

	general updates and bug fixes

### 2004.2.2.4

	Changed get-macsforhost to Get-FoghostMacs. Added output if get-foghost returns multiple hosts

### 2004.2.2.3

	fix release note formatting error

### 2004.2.2.2

	added try catch for ciminstance for powershell 7 compatibility in windows when getting the current foghost without params

### 2004.2.2.1

    - Mainly a bug fix release for issues with pending mac handling.Ended up adding some extra helper functions along the way
    - Added more get functions for ease of use including
        - Get-FogGroupAssociations
        - Get-FogGroupByName
        - Get-FogGroups
        - Get-FogHostGroup (replaces Get-FogGroup, but kept Get-FogGroup as an alias as to not break anyones scripts)
        - Get-FogMacAddresses (has alias of Get-FogMacs)
        - Get-MacsForHost
    - Fixed Approve-FogPendingMac so it makes a given mac not pending instead of keeping it pending
    - Fixed Get-PendingMacsForHost so it uses less pipeline and more separate commands that was causing it to return all pending macs in some cases, rather than just for a given host
    - Added hostID param to get-foghost so you can get a host from the internal hostID if you already have that

























