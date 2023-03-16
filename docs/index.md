# FogAPI

This is the home for the online versions of the fog api powershell module.
When you run `get-help command-name -online` it will open the associated page on this website

## Helpful links

You can find more info on how to use the api itself at [simplified-api-documentation](https://news.fogproject.org/simplified-api-documentation/)

You can find the source code for this module on [github](https://github.com/darksidemilk/FogApi)

You can find more discussion on the module in the [Fog Forums](https://forums.fogproject.org/topic/12026/powershell-api-module)

You can also find the published version of this module in the [Powershell Gallery](https://www.powershellgallery.com/packages/FogApi)

## Configuring the api tokens

In order to use the api, you need to have it enabled in the fog server and you need the api token for the server and the one for your user.

The first time you try to run a command the settings.json file will automatically open
in notepad on windows, nano on linux, or TextEdit on Mac
You can also open the settings.json file and edit it manually before running your first command.
The default settings are explanations of where to find the proper settings since json can't have comments
You can also use Set-FogServerSettings to set the api tokens for the sever and your user in one command. You first need to obtain these keys/tokens from the fog web gui. replace fog-server in the below example links with the name of your internal fog server if different

- The fog API token is found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System
- The fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab
- the fog server name is the name of your fog server, it defaults to `fog-server` but can be updated if you aren't using that default name as the hostname or an alias

Once you've obtained these you can run the command like this to save your fog api settings for the current user in a json file under `$home/APPDATA/Roaming/FogApi/api-settings.json` (this appdata path is created in linux/mac home folders) 

```
Set-FogServerSettings -fogApiToken "SuperLongPastedFogToken" -fogUserToken "SuperLongPastedUserToken" -fogServer "fog-server-hostname"
```

## [about the fogapi module](about_FogApi.md)

This provides more information on using the fogapi module
and what it can be used for, installing etc.
It can also be read if the module is installed by using `Get-Help About_fogapi`

## [commands index](commands/index.md)

An index of the commands included in the module