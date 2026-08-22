function Invoke-FogApi {
<#
        .SYNOPSIS
           a cmdlet function for making fogAPI calls via powershell

        .DESCRIPTION
            Takes a few parameters with some pulled from settings.json and others are put in from the wrapper cmdlets
            Makes a call to the api of a fog server and returns the results of the call
            The returned value is an object that can then be easily filtered, processed,
             and otherwise manipulated in poweshell.
            The defaults for each setting explain how to find or a description of the property needed.
            fogApiToken = "fog API token found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System";
            fogUserToken = "your fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab";
            fogServer = "your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer";

        .PARAMETER serverSettings
            this variable pulls the values from settings.json and assigns the values to
            the associated params. The defaults explain how to get the needed settings
            fogApiToken = "fog API token found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System";
            fogUserToken = "your fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab";
            fogServer = "your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer";

        .PARAMETER fogApiToken
            a string of your fogApiToken gotten from the fog web ui.
            this value is pulled from the settings.json file

        .PARAMETER fogUserToken
           a string of your fog user token gotten from the fog web ui in the user section.
           this value is pulled from the settings.json file

        .PARAMETER fogServer
            The hostname or ip address of your fogserver,
            defaults to the default name fog-server
            this value is pulled from the settings.json file

        .PARAMETER uriPath
            Put in the path of the apicall that would follow http://fog-server/fog/
            i.e. 'host/1234' would access the host with an id of 1234
            This is filled by the wrapper commands using parameter validation to
            help ensure using the proper object names for the url

        .PARAMETER Method
          Defaults to 'Get' can also be Post, put, or delete, this param is handled better
          by the wrapper functions
          get is Get-fogObject
          post is New-fogObject
          delete is Remove-fogObject
          put is Update-fogObject

        .PARAMETER jsonData
            The jsondata string for including data in the body of a request

        .EXAMPLE
            Invoke-FogApi;

            if you had the api tokens set as default values and wanted to get all hosts and info you could run this, assuming your fogserver is accessible on http://fog-server

        .Example
            Invoke-FogApi -fogServer "rawr" -uriPath "host/123" -Method "Put" -jsonData "{ `"name`": meow }";
        
            if your fogserver was named rawr and you wanted to put rename host 123 to meow

        .NOTES
            The online version of this help takes you to the fog project api help page
            See Also https://news.fogproject.org/simplified-api-documentation/
#>

    [CmdletBinding()]
    param (
        [string]$uriPath,
        [string]$Method="GET",
        [string]$jsonData
    )

    process {
        Write-Verbose "Pulling settings from settings file"
        # Set-FogServerSettings;
        $serverSettings = Get-FogServerSettings;
    
        [string]$fogApiToken = $serverSettings.fogApiToken;
        [string]$fogUserToken = $serverSettings.fogUserToken;
        [string]$fogServer = $serverSettings.fogServer;
    
        if ($fogServer -like "http*") {
            $baseUri = "$fogServer/fog";
        } else {
            $baseUri = "http://$fogServer/fog";
        }
    
        # Create headers
        Write-Verbose "Building Headers...";
        $headers = @{};
        $headers.Add('fog-api-token', $fogApiToken);
        $headers.Add('fog-user-token', $fogUserToken);
    
        # Set the Uri
        Write-Verbose "Building api call URI...";
        $uri = "$baseUri/$uriPath";
        $uri = $uri.Replace('//','/')
        if ($fogServer -notlike "https://*") {
            $uri = $uri.Replace('http:/','http://')
        } else {
            $uri = $uri.Replace('https:/','https://')
        }
    
    
        $apiCall = @{
            Uri = $uri;
            Method = $Method;
            Headers = $headers;
            Body = $jsonData;
            ContentType = "application/json"
        }
        if ($null -eq $apiCall.Body -OR $apiCall.Body -eq "") {
            Write-Verbose "removing body from call as it is null"
            $apiCall.Remove("Body");
        } else {
            if ($apiCall.Method -eq "GET") {
                Write-Warning "Body exists for a GET request, this may need to be a POST request if you're changing things?";
                # $apiCall.Method = "POST";
                # $Method = "POST"
            }
        } 
        # } else {
        #     if (!($apiCall.Body.GetType() -eq "string")) {
        #         $apiCall.Body = $apiCall.Body | ConvertTo-Json; 
        #     }
        # }
        Write-Verbose "$Method`ing $jsonData to/from $uri";
        try {
            $result = Invoke-RestMethod @apiCall -ea Stop;
        } catch {
            $failure = $_;
            $response = $failure.Exception.Response;
            $status = if ($null -ne $response) { [int]$response.StatusCode } else { 0 };

            if ($status -ge 400) {
                # An HTTP error status is the server's considered answer, not a
                # transport or parsing problem. Retrying it through
                # Invoke-WebRequest gets the identical refusal, doubles every
                # failing request, and -- because the caller then sees the
                # SECOND exception -- replaces the reason with a bare status
                # line. "Response status code does not indicate success: 406"
                # is what a caller used to get for what the server actually
                # said, which was "Invalid hostname; must be 1-15 of these
                # characters".
                #
                # FOG puts that reason in the response body, and PowerShell
                # hands the body over as ErrorDetails.Message.
                $detail = $failure.ErrorDetails.Message;
                if ([string]::IsNullOrWhiteSpace($detail)) { throw; }
                throw [System.Exception]::new(
                    ("FOG API {0} {1} failed with HTTP {2}: {3}" -f $Method, $uri, $status, $detail.Trim()),
                    $failure.Exception
                );
            }

            # Everything else falls back, which is what this catch was for:
            # FOG answers some successful writes with an empty body, and
            # Invoke-RestMethod cannot parse that as JSON.
            Write-Verbose "Invoke-RestMethod failed without an HTTP error status, retrying with Invoke-WebRequest";
            $result = Invoke-WebRequest @apiCall;
        }
        Write-Verbose "finished api call";
        return $result;
    }

}
