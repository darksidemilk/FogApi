function ConvertTo-FogFilterQuery {
    <#
    .SYNOPSIS
    Turns a -Filter hashtable into the query string FOG's list routes expect.

    .DESCRIPTION
    FOG 1.6 accepts a server side column filter on the generic read routes --
    list, count, names and ids -- as `?filter=<url encoded query string>`,
    documented as components.parameters.filter in the OpenAPI document from
    1.6.0-beta.3894 onward.

    The wire format is a query string nested inside one query parameter:
    field=value, joined with &, ANDed together. So the whole thing has to be
    encoded once as a unit, which is fiddly enough by hand that asking callers
    to do it would guarantee mistakes. A hashtable is what a PowerShell caller
    already reaches for, so this takes @{ hostID = 154 } and produces
    filter=hostID%3D154.

    An array value becomes a comma separated list, because that is what the
    server treats as "match any of these" -- Route::handleWhereItems() splits
    on commas before it builds the where clause.

    Only fields the class declares are accepted by the server. Anything else
    answers 400 naming the offending key, and credential fields are refused
    outright, so there is nothing to validate here that the server does not
    validate better. This deliberately does not keep a copy of the field list:
    a stale local copy would reject a filter the server would have accepted.

    .PARAMETER Filter
    Field/value pairs to filter on. Values may be arrays.

    .EXAMPLE
    ConvertTo-FogFilterQuery -Filter @{ hostID = 154 }

    Returns: filter=hostID%3D154

    .EXAMPLE
    ConvertTo-FogFilterQuery -Filter @{ hostID = 154; type = 'error' }

    Returns filter= with hostID=154&type=error encoded as one value.

    .EXAMPLE
    ConvertTo-FogFilterQuery -Filter @{ stateID = @(1,3) }

    Returns filter= with stateID=1,3 encoded, which the server reads as
    "stateID is either 1 or 3".
    #>
    [CmdletBinding()]
    [OutputType('System.String')]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Filter
    )

    process {
        if ($Filter.Keys.Count -eq 0) { return ''; }

        $pairs = foreach ($key in $Filter.Keys) {
            $value = $Filter[$key];
            # An array is the server's "any of these", expressed as a comma
            # separated value. Joined before encoding so the commas survive
            # as commas rather than becoming %2C, which parse_str would not
            # split on.
            if ($value -is [array]) {
                $value = ($value -join ',');
            }
            "$key=$value";
        }

        # Encoded as ONE value: the inner string is itself a query string, so
        # its = and & must not be read as the outer query's separators.
        'filter=' + [uri]::EscapeDataString(($pairs -join '&'));
    }
}
