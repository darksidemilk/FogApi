function Get-FogPagedResult {
    <#
    .SYNOPSIS
    Walks a fog 1.6 paged list endpoint and returns every row as a single assembled result

    .DESCRIPTION
    FOG 1.6 added DataTables style paging to its list routes. An unbounded request is silently capped
    at MAX_ROWS (10000) by FOGManagerController::limit(), so any list call that sends no paging params
    returns a partial result with no error. This helper always sends explicit start and length params
    and then follows the servers nextUrl until it is null, assembling every page into one result.

    Termination is driven purely by nextUrl. The recordsFiltered count is deliberately not used because
    the site plugin rewrites it to the post scoping count for site restricted users, and the truncated
    flag is deliberately not used because the server only sets it when it imposed the cap itself, which
    never happens once we send our own paging params.

    FOG 1.5 has no paging and ignores the query string, so it returns its entire list in one response
    with no nextUrl property. In that case the loop exits after one pass and First/Skip are applied
    client side so behaviour is identical across versions from the callers point of view.

    .PARAMETER uriPath
    the api path to page through, without a query string, e.g. host or tasklog

    .PARAMETER Method
    the http method, defaults to GET. Only list shaped routes page

    .PARAMETER jsonData
    a request body, if the route needs one

    .PARAMETER First
    only return the first n objects, stops requesting pages once satisfied

    .PARAMETER Skip
    start paging at this row offset

    .PARAMETER PageSize
    rows to request per api call, defaults to 1000

    .EXAMPLE
    Get-FogPagedResult -uriPath host

    This will request host?start=0&length=1000 and keep following nextUrl until every host is collected.

    Expected output:
    { "count": 1, "data": [ { "name": "MeowMachine", "id": 42 } ] }

    .EXAMPLE
    (Get-FogPagedResult -uriPath tasklog -First 50).data

    Gets the 50 most recent imaging log entries without walking the whole table, which on a server
    with any history is the difference between one request and dozens.

    .NOTES
    The page is advanced by the number of rows actually returned rather than by the requested length,
    because the expand path forces length to EXPAND_MAX_ITEMS (2500) server side and so can hand back a
    smaller page than was asked for.

    Public because it is useful on its own: Get-FogObject covers the core objects, but a route it does
    not model, or one reached with a filter or expand segment, still needs paging, and hand rolling the
    nextUrl walk per caller is how partial results creep back in.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        [string]$uriPath,
        [Parameter(Position=1)]
        [string]$Method = 'GET',
        [Parameter()]
        [string]$jsonData,
        [Parameter()]
        [int]$First,
        [Parameter()]
        [int]$Skip,
        [Parameter()]
        [int]$PageSize = 1000
    )

    process {
        if ($PageSize -le 0) { $PageSize = 1000; }
        [int]$start = [Math]::Max(0, $Skip);
        $basePath = $uriPath;
        $apiInvoke = @{
            uriPath = $uriPath;
            Method = $Method;
        }
        if (-not [string]::IsNullOrEmpty($jsonData)) {
            $apiInvoke.jsonData = $jsonData;
        }
        $all = [System.Collections.Generic.List[object]]::new();
        $lastPage = $null;
        [bool]$serverPaged = $false;
        [int]$pageNum = 0;
        [int]$maxPages = 10000; #safety net so a server side change can never spin forever

        while ($true) {
            $pageNum++;
            $pageInvoke = $apiInvoke.Clone();
            # `&` when the caller already put a query string on the path --
            # a -Filter arrives that way. Hardcoding `?` produced
            # tasklog?filter=x?start=0, which the server reads as a filter
            # value of "x?start=0" and then rejects as an unknown field.
            $joiner = if ($basePath.Contains('?')) { '&' } else { '?' };
            $pageInvoke.uriPath = "${basePath}${joiner}start=$start&length=$PageSize";
            Write-Verbose "paging: requesting $($pageInvoke.uriPath)";

            $page = Add-FogResultData (Invoke-FogApi @pageInvoke);
            if ($null -eq $page) { break; }
            $lastPage = $page;

            if ($pageNum -eq 1) {
                #1.6 responses carry the paging envelope, 1.5 responses have neither property
                $serverPaged = ($null -ne ($page | Get-Member -Name recordsReturned -ea 0)) -OR `
                               ($null -ne ($page | Get-Member -Name nextUrl -ea 0));
                if (!$serverPaged) {
                    Write-Verbose "server did not page this response, treating it as a complete 1.5 style list";
                }
            }

            $rows = @($page.data);
            if ($rows.Count -gt 0) { $all.AddRange([object[]]$rows); }
            Write-Verbose "paging: page $pageNum returned $($rows.Count) rows, $($all.Count) collected so far";

            if (!$serverPaged) { break; }
            if ($First -gt 0 -AND $all.Count -ge $First) {
                Write-Verbose "paging: collected enough rows for -First $First, stopping";
                break;
            }
            if ([string]::IsNullOrEmpty($page.nextUrl)) {
                Write-Verbose "paging: nextUrl is null, all pages collected";
                break;
            }
            if ($rows.Count -eq 0) {
                Write-Verbose "paging: nextUrl was set but the page was empty, stopping to avoid a loop";
                break;
            }
            if ($pageNum -ge $maxPages) {
                Write-Warning "Get-FogPagedResult stopped after $maxPages pages as a safety limit, the result may be incomplete";
                break;
            }

            #advance by rows actually returned, the expand path can hand back a smaller page than requested
            $start += $rows.Count;
            Write-Progress -Activity "Getting $basePath from fog" -Status "$($all.Count) collected" -CurrentOperation "page $pageNum";
        }
        if ($pageNum -gt 1) { Write-Progress -Activity "Getting $basePath from fog" -Completed; }

        $out = @($all);
        #1.5 never paged, so honour Skip here instead of via the start param
        if (!$serverPaged -AND $Skip -gt 0) { $out = @($out | Select-Object -Skip $Skip); }
        if ($First -gt 0) { $out = @($out | Select-Object -First $First); }

        if ($null -eq $lastPage) { return $null; }

        $result = $lastPage.PSObject.Copy();
        $result | Add-Member -NotePropertyName data -NotePropertyValue $out -Force;
        $result | Add-Member -NotePropertyName count -NotePropertyValue $out.Count -Force;
        if ($serverPaged) {
            $result | Add-Member -NotePropertyName recordsReturned -NotePropertyValue $out.Count -Force;
            #the per page links describe a single page and are meaningless on an assembled result
            foreach ($linkProp in @('firstUrl','prevUrl','nextUrl','lastUrl')) {
                if ($null -ne ($result | Get-Member -Name $linkProp -ea 0)) {
                    $result | Add-Member -NotePropertyName $linkProp -NotePropertyValue $null -Force;
                }
            }
        }
        return $result;
    }

}
