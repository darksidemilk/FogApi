#
# Shared helpers for the FogApi Pester suite.
# Not a *.Tests.ps1 file, so Pester does not auto-discover it - it is
# explicitly imported by the test files and by Invoke-FogApiTests.ps1.
#
# The convention these helpers rely on: a function's comment-based help can
# include, inside an .EXAMPLE block's remarks (after the normal prose
# description), a line that is exactly "Expected output:" followed by a
# JSON payload. Get-FogExampleCase turns every such annotated example into
# a Pester test case; Get-FogMockResponse fakes the one network seam
# (Invoke-FogApi) all of those examples ultimately call through.
#

$script:FixturesPath = Join-Path $PSScriptRoot 'Fixtures'

function Get-FogExampleCase {
    <#
    .SYNOPSIS
    Builds Pester test cases from Expected output: annotated .EXAMPLE blocks.

    .DESCRIPTION
    For each given function name, reads its comment-based help via Get-Help
    (the native help engine - not the generated markdown, so PlatyPS's
    single-line-example-code limitation does not apply here) and emits one
    case per .EXAMPLE whose remarks contain an "Expected output:" marker.
    Throws immediately if a marker's payload is not valid JSON, so a typo in
    the docs fails fast at test discovery instead of silently being skipped.

    .PARAMETER FunctionName
    One or more public function names to inspect for annotated examples.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$FunctionName
    )

    $cases = New-Object System.Collections.Generic.List[object]

    foreach ($name in $FunctionName) {
        $help = Get-Help -Name $name -Full
        $examples = $help.Examples.Example
        if ($null -eq $examples) {
            continue
        }

        foreach ($example in $examples) {
            $remarksText = ($example.remarks | ForEach-Object { $_.Text }) -join "`n"
            $match = [regex]::Match($remarksText, '(?ms)^\s*Expected output:\s*\r?\n(?<json>.+)\z')
            if (-not $match.Success) {
                continue
            }

            $jsonText = $match.Groups['json'].Value.Trim()
            try {
                $null = $jsonText | ConvertFrom-Json -ErrorAction Stop
            } catch {
                throw "Function '$name' has an Expected output: block that is not valid JSON: $($_.Exception.Message)`nPayload was:`n$jsonText"
            }

            $cases.Add(@{
                FunctionName = $name
                Code         = ($example.code -join "`n").Trim()
                ExpectedJson = $jsonText
            })
        }
    }

    return $cases.ToArray()
}

function Get-FogMockResponse {
    <#
    .SYNOPSIS
    Fixture lookup table standing in for a real Fog server's responses.

    .DESCRIPTION
    Keyed on the core-object-type portion of the uriPath plus the HTTP
    method, since one fixture is reused across many wrapper functions that
    all funnel through Invoke-FogApi. Throws a clear error for an unmapped
    combination rather than silently returning $null, so a gap in fixture
    coverage fails loudly instead of producing a confusing downstream test
    failure.

    Any query string is stripped before the lookup. Get-FogObject now always
    sends explicit ?start=N&length=N paging params (see Get-FogPagedResult -
    FOG 1.6 silently caps an unpaged list at MAX_ROWS), and those params
    select a page rather than a fixture. The fixtures are single-page
    responses carrying no nextUrl, so the pager treats each as a complete
    result and stops after one request.

    .PARAMETER uriPath
    The uriPath Invoke-FogApi was called with, including any query string.

    .PARAMETER Method
    The HTTP method Invoke-FogApi was called with.

    .PARAMETER jsonData
    The request body, if any - used to echo back a plausible "created"
    object for POSTs that create a new object.
    #>
    [CmdletBinding()]
    param (
        [string]$uriPath,
        [string]$Method,
        [string]$jsonData
    )

    function Get-Fixture([string]$name) {
        Get-Content (Join-Path $script:FixturesPath $name) -Raw | ConvertFrom-Json
    }

    # Paging params select a page, not a fixture - match on the path alone.
    $queryString = ''
    if ($uriPath -match '^(?<path>[^?]*)\?(?<query>.*)$') {
        $uriPath = $Matches['path']
        $queryString = $Matches['query']
    }

    switch -regex ($uriPath) {
        '^system/info$' {
            if ($Method -eq 'GET') { return Get-Fixture 'version-info.json' }
        }
        '^module$' {
            if ($Method -eq 'GET') { return Get-Fixture 'modules.json' }
        }
        '^host/\d+/edit$' {
            if ($Method -eq 'PUT') {
                if ([string]::IsNullOrEmpty($jsonData)) { return Get-Fixture 'host.json' }
                return $jsonData | ConvertFrom-Json
            }
        }
        '^host/\d+$' {
            if ($Method -eq 'GET') { return Get-Fixture 'host.json' }
        }
        '^host$' {
            if ($Method -eq 'GET') { return Get-Fixture 'hosts.json' }
            if ($Method -eq 'POST') {
                $created = if ([string]::IsNullOrEmpty($jsonData)) { [PSCustomObject]@{} } else { $jsonData | ConvertFrom-Json }
                $created | Add-Member -MemberType NoteProperty -Name id -Value 42 -Force
                return $created
            }
        }
        '^groupassociation$' {
            if ($Method -eq 'GET') { return Get-Fixture 'groupassociations.json' }
            if ($Method -eq 'POST') {
                $created = if ([string]::IsNullOrEmpty($jsonData)) { [PSCustomObject]@{} } else { $jsonData | ConvertFrom-Json }
                $created | Add-Member -MemberType NoteProperty -Name id -Value 77 -Force
                return $created
            }
        }
        '^groupassociation/\d+/delete$' {
            if ($Method -eq 'DELETE') { return Get-Fixture 'delete-result.json' }
        }
        '^group/search/.+$' {
            if ($Method -eq 'GET') { return Get-Fixture 'groups-search.json' }
        }
        '^group/\d+/edit$' {
            if ($Method -eq 'PUT') {
                if ([string]::IsNullOrEmpty($jsonData)) { return Get-Fixture 'groups-search.json' }
                return $jsonData | ConvertFrom-Json
            }
        }
        '^scheduledtask$' {
            if ($Method -eq 'POST') {
                $created = if ([string]::IsNullOrEmpty($jsonData)) { [PSCustomObject]@{} } else { $jsonData | ConvertFrom-Json }
                $created | Add-Member -MemberType NoteProperty -Name id -Value 88 -Force
                return $created
            }
            # scheduledtasks.json: the plain list. This arm used to answer with
            # scheduledtasks-current.json, an empty active-task fixture, so the
            # list route returned nothing -- invisible until a generated list
            # cmdlet asked. /current is handled by convention now.
            if ($Method -eq 'GET') { return Get-Fixture 'scheduledtasks.json' }
        }
        '^macaddressassociation$' {
            if ($Method -eq 'GET') { return Get-Fixture 'macaddressassociations.json' }
            if ($Method -eq 'POST') {
                $created = if ([string]::IsNullOrEmpty($jsonData)) { [PSCustomObject]@{} } else { $jsonData | ConvertFrom-Json }
                $created | Add-Member -MemberType NoteProperty -Name id -Value 99 -Force
                return $created
            }
        }
        '^macaddressassociation/\d+/edit$' {
            if ($Method -eq 'PUT') {
                if ([string]::IsNullOrEmpty($jsonData)) { return Get-Fixture 'macaddressassociations.json' }
                return $jsonData | ConvertFrom-Json
            }
        }
        '^macaddressassociation/\d+/delete$' {
            if ($Method -eq 'DELETE') { return Get-Fixture 'delete-result.json' }
        }
        '^group$' {
            if ($Method -eq 'GET') { return Get-Fixture 'groups.json' }
        }
        '^group/\d+$' {
            if ($Method -eq 'GET') { return Get-Fixture 'group.json' }
        }
        '^snapin$' {
            if ($Method -eq 'GET') { return Get-Fixture 'snapins.json' }
        }
        '^snapin/\d+$' {
            if ($Method -eq 'GET') { return Get-Fixture 'snapin.json' }
        }
        '^snapinassociation$' {
            if ($Method -eq 'GET') { return Get-Fixture 'snapinassociations.json' }
            if ($Method -eq 'POST') {
                $created = if ([string]::IsNullOrEmpty($jsonData)) { [PSCustomObject]@{} } else { $jsonData | ConvertFrom-Json }
                $created | Add-Member -MemberType NoteProperty -Name id -Value 55 -Force
                return $created
            }
        }
        '^snapinassociation/\d+/delete$' {
            if ($Method -eq 'DELETE') { return Get-Fixture 'delete-result.json' }
        }
        '^setting$' {
            if ($Method -eq 'GET') { return Get-Fixture 'settings.json' }
        }
        '^setting/\d+$' {
            if ($Method -eq 'GET') { return Get-Fixture 'setting.json' }
        }
        '^setting/\d+/edit$' {
            if ($Method -eq 'PUT') {
                if ([string]::IsNullOrEmpty($jsonData)) { return Get-Fixture 'setting.json' }
                return $jsonData | ConvertFrom-Json
            }
        }
        '^image$' {
            if ($Method -eq 'GET') { return Get-Fixture 'images.json' }
        }
        '^inventory/new$' {
            if ($Method -eq 'POST') { return $jsonData | ConvertFrom-Json }
        }
        '^host/search/.+$' {
            if ($Method -eq 'GET') { return Get-Fixture 'hosts.json' }
        }
        '^unisearch/.+$' {
            if ($Method -eq 'GET') { return Get-Fixture 'unisearch.json' }
        }
    }

    # Convention-based fallback.
    #
    # The table above is hand-maintained, which was fine for a demand-driven
    # module and does not survive generated cmdlets: the spec resolves to over
    # two hundred of them across fifty-two classes, and four hand-written switch
    # arms each is eight hundred arms nobody will keep correct.
    #
    # Generated cmdlets all hit the same shapes, so the shapes are matched
    # instead. A class opts in purely by having a fixture file with the
    # conventional name -- there is nothing to register. The explicit table
    # still wins, so nothing above changes behaviour.
    #
    # A conventional list fixture holds exactly ONE row. The generated examples
    # assert a single-element array, because an emitter has no way to know how
    # many rows a server would return; multi-row behaviour is asserted on the
    # request sequence in Get-FogPagedResult.Tests.ps1 instead, which is where
    # it belongs.
    #
    #   GET    {class}                 -> {class}s.json
    #   GET    {class}/{id}            -> {class}.json
    #   GET    {class}/search/{item}   -> {class}s-search.json, else {class}s.json
    #   POST   {class}                 -> the body echoed back with an id
    #   PUT    {class}/{id}/edit       -> the body echoed back with that id
    #   DELETE {class}/{id}/delete     -> delete-result.json
    function Test-Fixture([string]$name) {
        Test-Path -LiteralPath (Join-Path $script:FixturesPath $name)
    }
    function New-EchoedObject([string]$body, $id) {
        # A real server answers a create or an edit with the stored object, so
        # the mock echoes the request back rather than inventing a shape. An id
        # is added when the caller did not send one, which is what a create does.
        $echo = if ([string]::IsNullOrEmpty($body)) { [pscustomobject]@{} } else { $body | ConvertFrom-Json }
        if ($null -ne $id -and -not ($echo.PSObject.Properties.Name -contains 'id')) {
            $echo | Add-Member -NotePropertyName 'id' -NotePropertyValue $id
        }
        return $echo
    }

    function Get-FixtureRows([string]$name) {
        # The rows out of a list fixture, whichever property holds them. A 1.5
        # style fixture keys them by class name ({count, printers[]}), a 1.6 one
        # by 'data'. Same rule Add-FogResultData uses: take the property holding
        # a collection.
        $fixture = Get-Fixture $name
        $rowProp = @($fixture.PSObject.Properties |
            Where-Object { $_.Name -ne 'count' -and $_.Value -is [System.Collections.IEnumerable] -and $_.Value -isnot [string] } |
            Select-Object -First 1)
        if ($rowProp.Count -eq 0) { return @() }
        return @($rowProp[0].Value)
    }

    function Get-RequestedFilter {
        # ?filter= is a query string nested inside one query parameter --
        # field=value joined with &, url encoded as a unit. Decoded here so the
        # mock can apply it, because a mock that ignores the filter makes a
        # filtered call and an unfiltered one indistinguishable, and then no
        # test can prove the filter was sent at all.
        if ([string]::IsNullOrEmpty($queryString)) { return $null }
        # Parsed by hand rather than with System.Web.HttpUtility: that assembly
        # is not loaded by default on Windows PowerShell 5.1, which this module
        # still supports, and pulling in an Add-Type for one lookup is a worse
        # trade than four lines of splitting.
        $raw = $null
        foreach ($outerPair in ($queryString -split '&')) {
            if ($outerPair -match '^filter=(?<v>.*)$') {
                $raw = [uri]::UnescapeDataString($Matches['v'])
                break
            }
        }
        if ([string]::IsNullOrEmpty($raw)) { return $null }
        $parsed = @{}
        foreach ($pair in ($raw -split '&')) {
            if ($pair -notmatch '^(?<k>[^=]+)=(?<v>.*)$') { continue }
            $parsed[$Matches['k']] = $Matches['v']
        }
        if ($parsed.Keys.Count -eq 0) { return $null }
        return $parsed
    }

    function Select-FilteredRows($rows, $filter) {
        # AND across keys, and a comma separated value matches any of its
        # parts -- the same two rules Route::handleWhereItems() applies.
        # Compared as strings because the fixture holds real types and the
        # filter arrives off a URL, where everything is text.
        if ($null -eq $filter) { return @($rows) }
        return @($rows | Where-Object {
            $row = $_
            $keep = $true
            foreach ($key in $filter.Keys) {
                $want = @($filter[$key] -split ',')
                $have = [string]$row.$key
                if ($want -notcontains $have) { $keep = $false; break }
            }
            $keep
        })
    }

    $class = $null
    $shape = $null
    $objectId = $null
    switch -regex ($uriPath) {
        '^(?<class>[a-z]+)$'                          { $class = $Matches['class']; $shape = 'collection' }
        '^(?<class>[a-z]+)/search/.+$'                { $class = $Matches['class']; $shape = 'search' }
        '^(?<class>[a-z]+)/current$'                  { $class = $Matches['class']; $shape = 'current' }
        '^(?<class>[a-z]+)/count$'                    { $class = $Matches['class']; $shape = 'count' }
        '^(?<class>[a-z]+)/names$'                    { $class = $Matches['class']; $shape = 'names' }
        '^(?<class>[a-z]+)/ids$'                      { $class = $Matches['class']; $shape = 'ids' }
        '^(?<class>[a-z]+)/(?<id>\d+)$'               { $class = $Matches['class']; $objectId = $Matches['id']; $shape = 'single' }
        '^(?<class>[a-z]+)/(?<id>\d+)/edit$'          { $class = $Matches['class']; $objectId = $Matches['id']; $shape = 'edit' }
        '^(?<class>[a-z]+)/(?<id>\d+)/delete$'        { $class = $Matches['class']; $objectId = $Matches['id']; $shape = 'delete' }
        '^(?<class>[a-z]+)/(?<id>\d+)/task$'          { $class = $Matches['class']; $objectId = $Matches['id']; $shape = 'task' }
        '^(?<class>[a-z]+)/(?<id>\d+)/cancel$'        { $class = $Matches['class']; $objectId = $Matches['id']; $shape = 'cancel' }
    }

    if ($class) {
        switch ("$Method/$shape") {
            'GET/collection' {
                if (Test-Fixture "$($class)s.json") {
                    $fixture = Get-Fixture "$($class)s.json"
                    $filter = Get-RequestedFilter
                    if ($null -eq $filter) { return $fixture }
                    # Rewrite the rows in place so the envelope keeps whatever
                    # shape the fixture uses -- 1.5 keys them by class name,
                    # 1.6 by 'data' -- and any count property stays honest.
                    $kept = Select-FilteredRows (Get-FixtureRows "$($class)s.json") $filter
                    $rowProp = @($fixture.PSObject.Properties |
                        Where-Object { $_.Name -ne 'count' -and $_.Value -is [System.Collections.IEnumerable] -and $_.Value -isnot [string] } |
                        Select-Object -First 1)
                    if ($rowProp.Count -gt 0) { $fixture.($rowProp[0].Name) = $kept }
                    if ($fixture.PSObject.Properties.Name -contains 'count') { $fixture.count = $kept.Count }
                    return $fixture
                }
            }
            'GET/single'     { if (Test-Fixture "$class.json")     { return Get-Fixture "$class.json" } }
            # /current is a state-filtered view of the same table, and a real
            # server answers it with the same list envelope a list route
            # returns -- verified against 1.6.0-beta.3894: GET /task/current
            # gives draw/recordsTotal/recordsFiltered/data/_lang, not a bare
            # array. So it is DERIVED from the list fixture for the same reason
            # count, names and ids are: one file per class is the only way the
            # views cannot contradict each other, and it is also the file the
            # emitter builds the "Expected output:" block from, so a separate
            # -current fixture could only ever drift away from the documented
            # example. tasks-current.json and scheduledtasks-current.json were
            # exactly that drift -- hand-written, in the 1.5 {count,tasks[]}
            # shape, and empty, so every active-task example asserted a row
            # against nothing.
            #
            # Which rows a real server considers active is not modelled: the
            # fixture holds one row and /current returns it. That the cmdlet
            # asked for /current rather than the plain list is asserted on the
            # request path in TaskRoutes.Tests.ps1, which is where a request
            # fact belongs.
            'GET/current'    { if (Test-Fixture "$($class)s.json")  { return Get-Fixture "$($class)s.json" } }
            'GET/search'     {
                if (Test-Fixture "$($class)s-search.json") { return Get-Fixture "$($class)s-search.json" }
                if (Test-Fixture "$($class)s.json")        { return Get-Fixture "$($class)s.json" }
            }
            # count, names and ids are DERIVED from the list fixture rather than
            # each getting a fixture of their own. A real server computes them
            # from the same rows, so deriving is the only way the four cannot
            # contradict each other, and a class opts into all four by adding
            # one file. Shapes match the server exactly: {"total":N}, a bare
            # array of id/name pairs, and a bare array of ids.
            'GET/count' {
                if (Test-Fixture "$($class)s.json") {
                    return [pscustomobject]@{ total = @(Select-FilteredRows (Get-FixtureRows "$($class)s.json") (Get-RequestedFilter)).Count }
                }
            }
            'GET/names' {
                if (Test-Fixture "$($class)s.json") {
                    return @(Select-FilteredRows (Get-FixtureRows "$($class)s.json") (Get-RequestedFilter) |
                        ForEach-Object { [pscustomobject]@{ id = $_.id; name = $_.name } })
                }
            }
            'GET/ids' {
                if (Test-Fixture "$($class)s.json") {
                    return @(Select-FilteredRows (Get-FixtureRows "$($class)s.json") (Get-RequestedFilter) | ForEach-Object { $_.id })
                }
            }
            # Tasking and cancelling answer 200 with an EMPTY body. That is not
            # a placeholder -- it is what the server does, confirmed twice
            # against a live 1.6 server (beta.3860 and beta.3894): POST
            # /host/{id}/task returns "" and the task really is created, and
            # DELETE /host/{id}/cancel returns "" on a task that was genuinely
            # active. So the generated "Expected output: """ on every
            # Start-Fog*Task and Stop-Fog*Task is correct and must not be
            # "fixed" to look like a created object.
            #
            # task-create.json used to answer {"id":501,"success":true} here,
            # which is a shape FOG has never returned. It was hand-written, and
            # it made three documented examples fail against their own module.
            #
            # Cancelling when nothing is running is the one case that is NOT
            # empty: the server answers 409 {"msg":"Host has no active task to
            # cancel"}. Not modelled, because the mock has no notion of a task
            # being active; a caller that needs that branch wants the real
            # server suite.
            'POST/task'       { return '' }
            'DELETE/cancel'   { return '' }
            'POST/collection' { return New-EchoedObject -body $jsonData -id 1 }
            'PUT/edit'        { return New-EchoedObject -body $jsonData -id $objectId }
            'DELETE/delete'   { if (Test-Fixture 'delete-result.json') { return Get-Fixture 'delete-result.json' } }
        }
    }

    $qsNote = if ($queryString) { " (query string '$queryString' was stripped before lookup)" } else { '' }
    $hint = if ($class) {
        " The path matched the '$shape' shape for class '$class', so adding Tests/Fixtures/$($class)s.json (or $class.json for a single object) is enough - no change to this file is needed."
    } else { '' }
    throw "Get-FogMockResponse: no fixture mapped for uriPath '$uriPath' with Method '$Method'$qsNote.$hint"
}

function Test-FogIdLikeValue {
    <#
    .SYNOPSIS
    Loosened check used for properties whose name looks like an id (Test-FogExpectedSubset).

    .DESCRIPTION
    A real Fog server assigns its own ids on creation, so an Expected output: annotation's
    hardcoded id (fixture-authored, e.g. 42) will almost never match under -RealServer even
    when the call genuinely succeeded. For any property whose name ends in "id" (id, hostID,
    groupID, snapinID, ...) this is used instead of an exact-value comparison - it only checks
    that the actual value is present and looks like a real id (a non-negative integer, whether
    returned as a number or a numeric string), not that it equals the specific fixture value.
    This is strictly more permissive than exact equality, so it can't turn a currently-passing
    mocked assertion into a failing one.

    .PARAMETER Value
    The actual value returned for the id-like property.
    #>
    [CmdletBinding()]
    param (
        $Value
    )

    if ($null -eq $Value) {
        return $false
    }
    $asString = "$Value".Trim()
    if ([string]::IsNullOrEmpty($asString)) {
        return $false
    }
    return $asString -match '^\d+$'
}

function Test-FogExpectedSubset {
    <#
    .SYNOPSIS
    Recursively asserts that $Expected is a subset of $Actual.

    .DESCRIPTION
    Every scalar, property, and array element present in $Expected must be
    present and equal in $Actual, but $Actual may contain additional
    properties. This keeps documented Expected output: blocks short and
    resistant to churn as the real API returns more fields over time.
    Returns $true/$false rather than throwing, so callers can produce a
    clear Pester assertion failure message.

    Properties whose name ends in "id" (case-insensitive: id, hostID, groupID, snapinID, ...)
    are checked with Test-FogIdLikeValue instead of exact equality - see its help for why.

    .PARAMETER Actual
    The real value returned by the function under test.

    .PARAMETER Expected
    The value parsed from the function's Expected output: annotation.
    #>
    [CmdletBinding()]
    param (
        $Actual,
        $Expected
    )

    if ($null -eq $Expected) {
        return $null -eq $Actual
    }

    if ($Expected -is [System.Management.Automation.PSCustomObject]) {
        if ($null -eq $Actual) {
            return $false
        }
        foreach ($property in $Expected.PSObject.Properties) {
            $actualMember = $Actual.PSObject.Properties[$property.Name]
            if ($null -eq $actualMember) {
                return $false
            }
            $isIdLike = $property.Name -match '(?i)id$' -and $property.Value -isnot [System.Management.Automation.PSCustomObject] -and $property.Value -isnot [array]
            if ($isIdLike) {
                if (-not (Test-FogIdLikeValue -Value $actualMember.Value)) {
                    return $false
                }
                continue
            }
            if (-not (Test-FogExpectedSubset -Actual $actualMember.Value -Expected $property.Value)) {
                return $false
            }
        }
        return $true
    }

    if ($Expected -is [array]) {
        if ($null -eq $Actual -or $Actual.Count -lt $Expected.Count) {
            return $false
        }
        for ($i = 0; $i -lt $Expected.Count; $i++) {
            if (-not (Test-FogExpectedSubset -Actual $Actual[$i] -Expected $Expected[$i])) {
                return $false
            }
        }
        return $true
    }

    return $Expected -eq $Actual
}

function Get-FogParameterSetCoverage {
    <#
    .SYNOPSIS
    Reports, per function and per real parameter set, whether an example exists and is annotated.

    .DESCRIPTION
    Advisory/best-effort coverage report - not a test assertion, never throws on a gap. For each
    function, reflects on its actual parameter sets via Get-Command, then for every .EXAMPLE
    (annotated or not) uses the PowerShell parser to find which named parameters the example's
    invocation of that function binds, and matches that set against each parameter set's parameter
    list (a subset match - an example that binds no/few parameters is attributed to every
    parameter set it's consistent with, since this is informational, not a strict gate).

    .PARAMETER FunctionName
    One or more function names to report on.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$FunctionName
    )

    $records = New-Object System.Collections.Generic.List[object]

    foreach ($name in $FunctionName) {
        $command = Get-Command -Name $name -ErrorAction SilentlyContinue
        if ($null -eq $command -or $null -eq $command.ParameterSets -or $command.ParameterSets.Count -eq 0) {
            continue
        }

        $parameterSets = $command.ParameterSets
        $setParams = @{}
        if ($parameterSets.Count -eq 1 -and $parameterSets[0].Name -eq '__AllParameterSets') {
            $setParams['Default'] = @($parameterSets[0].Parameters.Name)
        } else {
            foreach ($set in $parameterSets) {
                $setParams[$set.Name] = @($set.Parameters.Name)
            }
        }

        $aliasNames = @(Get-Alias -Definition $name -ErrorAction SilentlyContinue | ForEach-Object Name)
        $matchNames = @($name) + $aliasNames

        $help = Get-Help -Name $name -Full
        $examples = @($help.Examples.Example)

        $setHasExample = @{}
        $setHasAnnotation = @{}
        foreach ($setName in $setParams.Keys) {
            $setHasExample[$setName] = $false
            $setHasAnnotation[$setName] = $false
        }

        foreach ($example in $examples) {
            $code = ($example.code -join "`n").Trim()
            $remarksText = ($example.remarks | ForEach-Object { $_.Text }) -join "`n"
            $isAnnotated = [bool]([regex]::IsMatch($remarksText, '(?ms)^\s*Expected output:\s*\r?\n'))

            $usedParams = New-Object System.Collections.Generic.List[string]
            try {
                $parseErrors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$null, [ref]$parseErrors)
                $commandAsts = $ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -and ($matchNames -contains $node.GetCommandName())
                }, $true)
                foreach ($cmdAst in $commandAsts) {
                    $cmdAst.CommandElements |
                        Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] } |
                        ForEach-Object { $usedParams.Add($_.ParameterName) }
                }
            } catch {
                Write-Warning "Get-FogParameterSetCoverage: could not parse an example for '$name': $($_.Exception.Message)"
            }
            $uniqueUsedParams = @($usedParams | Select-Object -Unique)

            foreach ($setName in $setParams.Keys) {
                $isSubset = $true
                foreach ($p in $uniqueUsedParams) {
                    if ($setParams[$setName] -notcontains $p) {
                        $isSubset = $false
                        break
                    }
                }
                if ($isSubset) {
                    $setHasExample[$setName] = $true
                    if ($isAnnotated) {
                        $setHasAnnotation[$setName] = $true
                    }
                }
            }
        }

        foreach ($setName in ($setParams.Keys | Sort-Object)) {
            $records.Add([PSCustomObject]@{
                FunctionName  = $name
                ParameterSet  = $setName
                HasExample    = $setHasExample[$setName]
                HasAnnotation = $setHasAnnotation[$setName]
            })
        }
    }

    return $records.ToArray()
}

function ConvertTo-FogCoverageMarkdown {
    <#
    .SYNOPSIS
    Formats Get-FogParameterSetCoverage records as a markdown checklist.

    .DESCRIPTION
    Groups by function, one checkbox line per parameter set: checked when an example is annotated
    with Expected output:, unchecked (with a reason) when an example exists but isn't annotated, or
    when no example targets that set at all. Purely a formatter - has no opinion on whether the
    result is "good enough"; that judgment is left to whoever reads the report.

    .PARAMETER Coverage
    Records produced by Get-FogParameterSetCoverage.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Coverage
    )

    $total = $Coverage.Count
    $annotated = @($Coverage | Where-Object HasAnnotation).Count

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# FogApi Expected output: coverage report')
    $lines.Add('')
    $lines.Add("$annotated / $total parameter sets have an annotated ``Expected output:`` example.")
    $lines.Add('')
    $lines.Add('This is an informational report, not a pass/fail gate - see docs/Contributing.md.')
    $lines.Add('')

    $byFunction = $Coverage | Group-Object FunctionName | Sort-Object Name

    foreach ($group in $byFunction) {
        $lines.Add("## $($group.Name)")
        $lines.Add('')
        foreach ($record in ($group.Group | Sort-Object ParameterSet)) {
            if ($record.HasAnnotation) {
                $lines.Add("- [x] $($record.ParameterSet)")
            } elseif ($record.HasExample) {
                $lines.Add("- [ ] $($record.ParameterSet) - example exists, not annotated with Expected output:")
            } else {
                $lines.Add("- [ ] $($record.ParameterSet) - no example")
            }
        }
        $lines.Add('')
    }

    return ($lines -join "`n")
}

function Register-FogApiMock {
    <#
    .SYNOPSIS
    Installs the Invoke-FogApi mock for the FogApi module.

    .DESCRIPTION
    Meant to be called from inside a Pester It/BeforeEach block. When -RealServer is set, the
    example still runs unmocked against a real, already-configured Fog server, but Invoke-FogApi
    is replaced with a recording passthrough (Invoke-FogRealServerCall) rather than doing nothing -
    every mutating call is journaled so Restore-FogRealServerState can revert it afterward.
    Initialize-FogRealServerJournal must have already run once before the first -RealServer call.

    .PARAMETER RealServer
    When set, real API calls still happen, but are journaled for later revert instead of
    running completely untracked.
    #>
    [CmdletBinding()]
    param (
        [switch]$RealServer
    )

    if ($RealServer) {
        if (-not $script:FogRealInvokeFogApi) {
            throw "Register-FogApiMock -RealServer: Initialize-FogRealServerJournal must be called first (normally from the test file's BeforeAll)."
        }
        Mock -ModuleName FogApi Invoke-FogApi {
            Invoke-FogRealServerCall -uriPath $uriPath -Method $Method -jsonData $jsonData
        }
        return
    }

    Mock -ModuleName FogApi Invoke-FogApi {
        Get-FogMockResponse -uriPath $uriPath -Method $Method -jsonData $jsonData
    }
}

function Initialize-FogRealServerJournal {
    <#
    .SYNOPSIS
    Prepares the -RealServer safety net: captures the real Invoke-FogApi implementation and
    resets the on-disk mutation journal.

    .DESCRIPTION
    Must run exactly once per -RealServer test run, before Invoke-FogApi is mocked for the first
    time in this Pester session (normally from the top of the Examples test file's BeforeAll,
    right after importing the FogApi module fresh) - that's the only point at which
    Get-Command still resolves the true, unmocked implementation. The captured scriptblock is
    what Invoke-FogRealServerCall and Restore-FogRealServerState call through to for every real
    HTTP call, including the revert calls they issue themselves.

    The journal is written to disk (not just kept in memory) as each mutation happens, so if the
    test run crashes or is killed mid-way, the journal file left behind still records exactly
    what changed and what its original value was, for manual recovery.

    .PARAMETER JournalPath
    Where to persist the newline-delimited JSON mutation journal. Truncated at the start of
    every run.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$JournalPath
    )

    $realCommand = Get-Command -Name Invoke-FogApi -Module FogApi -ErrorAction Stop
    $script:FogRealInvokeFogApi = $realCommand.ScriptBlock
    $script:FogRealServerJournalPath = $JournalPath

    $journalDir = Split-Path $JournalPath -Parent
    if ($journalDir -and -not (Test-Path $journalDir)) {
        New-Item -Path $journalDir -ItemType Directory -Force | Out-Null
    }
    Set-Content -Path $JournalPath -Value $null
}

function Invoke-FogRealServerCall {
    <#
    .SYNOPSIS
    Real-server Invoke-FogApi mock body: calls through to the true implementation, journaling
    anything mutating so Restore-FogRealServerState can revert it afterward.

    .DESCRIPTION
    GETs pass straight through untouched. PUTs (".../edit") snapshot the pre-edit state (via a
    GET of the same path with the /edit suffix stripped) before the real call, and journal only
    the specific fields the example's request body touched, so a later revert can restore just
    those fields without tripping Fog's own quirks around resending unchanged ones (e.g. a host's
    name). POSTs that create a addressable object (a bare object path, e.g. "host") are journaled
    with the created id so they can be deleted afterward; POSTs to a ".../task" path represent an
    already-dispatched real-world action (deploy, capture, snapin push, WoL) with no per-task
    cancel available, so they're recorded as informational/unrevertable instead. DELETEs snapshot
    what was destroyed (best-effort) purely so the final summary can show it - deleted data can't
    be restored through the API.

    .PARAMETER uriPath
    Passed straight through, see Invoke-FogApi.

    .PARAMETER Method
    Passed straight through, see Invoke-FogApi.

    .PARAMETER jsonData
    Passed straight through, see Invoke-FogApi.
    #>
    [CmdletBinding()]
    param(
        [string]$uriPath,
        [string]$Method = 'GET',
        [string]$jsonData
    )

    function Invoke-RealFogApi {
        param([string]$Path, [string]$Verb = 'GET', [string]$Body)
        $callArgs = @{ uriPath = $Path; Method = $Verb }
        if ($Body) { $callArgs.jsonData = $Body }
        try {
            & $script:FogRealInvokeFogApi @callArgs
        } catch {
            # HttpResponseException's own .Message is usually just the status line (e.g. "406
            # Not Acceptable") with no clue why - Fog's actual explanation is the response body,
            # which .ErrorDetails.Message carries when present. Surface it so a real-server
            # failure is self-diagnosing instead of a bare status code.
            $responseBody = $_.ErrorDetails.Message
            if ($responseBody) {
                throw "$Verb $Path failed: $($_.Exception.Message) - server response: $responseBody"
            }
            throw
        }
    }

    switch ($Method.ToUpperInvariant()) {
        'GET' {
            return Invoke-RealFogApi -Path $uriPath -Verb $Method
        }
        'PUT' {
            $readUri = $uriPath -replace '/edit$', ''
            $preState = $null
            $readError = $null
            try {
                $preState = Invoke-RealFogApi -Path $readUri -Verb 'GET'
            } catch {
                $readError = $_.Exception.Message
            }

            $result = Invoke-RealFogApi -Path $uriPath -Verb $Method -Body $jsonData

            if ($null -ne $preState -and $jsonData) {
                Add-FogRealServerJournalEntry -Kind 'edit' -UriPath $uriPath -ReadUri $readUri -PreState $preState -RequestJson $jsonData
            } else {
                Add-FogRealServerJournalEntry -Kind 'edit-untracked' -UriPath $uriPath -Note ($readError ?? 'no request body to know which fields to restore')
            }
            return $result
        }
        'POST' {
            $result = Invoke-RealFogApi -Path $uriPath -Verb $Method -Body $jsonData

            if ($uriPath -match '/task$') {
                Add-FogRealServerJournalEntry -Kind 'task' -UriPath $uriPath -Result $result
            } elseif ($null -ne $result.id) {
                Add-FogRealServerJournalEntry -Kind 'create' -UriPath $uriPath -CreatedId $result.id
            } else {
                Add-FogRealServerJournalEntry -Kind 'create-untracked' -UriPath $uriPath -Result $result
            }
            return $result
        }
        'DELETE' {
            $readUri = $uriPath -replace '/delete$', ''
            $preState = $null
            try {
                $preState = Invoke-RealFogApi -Path $readUri -Verb 'GET'
            } catch {
                # best-effort only - the delete still proceeds, and the summary just won't be able to show what was lost
            }

            $result = Invoke-RealFogApi -Path $uriPath -Verb $Method -Body $jsonData
            Add-FogRealServerJournalEntry -Kind 'delete' -UriPath $uriPath -PreState $preState
            return $result
        }
        default {
            return Invoke-RealFogApi -Path $uriPath -Verb $Method -Body $jsonData
        }
    }
}

function Add-FogRealServerJournalEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Kind,
        [Parameter(Mandatory = $true)]
        [string]$UriPath,
        [string]$ReadUri,
        $PreState,
        [string]$RequestJson,
        $CreatedId,
        $Result,
        [string]$Note
    )

    $entry = [PSCustomObject]@{
        Kind        = $Kind
        UriPath     = $UriPath
        ReadUri     = $ReadUri
        PreState    = $PreState
        RequestJson = $RequestJson
        CreatedId   = $CreatedId
        Result      = $Result
        Note        = $Note
    }
    ($entry | ConvertTo-Json -Depth 15 -Compress) | Add-Content -Path $script:FogRealServerJournalPath
}

function Restore-FogRealServerState {
    <#
    .SYNOPSIS
    Best-effort cleanup for a -RealServer run: the "cleanup script" that reverts/removes
    whatever the just-run examples changed on the real Fog server.

    .DESCRIPTION
    Reads the journal Invoke-FogRealServerCall wrote during the run and walks it in reverse
    (last mutation undone first), against the same real Invoke-FogApi implementation the run
    itself used:
    - 'edit' entries are reverted by PUTting back only the specific fields the original request
      changed, using the values captured before that PUT ran (e.g. undoes exactly a clobbered
      FOG_WEB_HOST setting).
    - 'create' entries are deleted by id.
    - 'task', 'create-untracked', 'delete', and 'edit-untracked' entries can't be safely or
      completely undone through the API (a dispatched task, a permanently deleted object, an
      edit whose pre-state couldn't be captured) - these are never silently dropped, they're
      returned in the summary so a human can decide what to do.

    Always call this from an AfterAll (or an outer try/finally), never conditioned on whether
    the examples passed - a mutation needs reverting regardless of whether the test that caused
    it happened to fail.

    .PARAMETER JournalPath
    The newline-delimited JSON journal file written by Invoke-FogRealServerCall during the run.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$JournalPath
    )

    $summary = [PSCustomObject]@{
        Restored        = New-Object System.Collections.Generic.List[string]
        FailedToRestore = New-Object System.Collections.Generic.List[string]
        Unrevertable    = New-Object System.Collections.Generic.List[string]
    }

    if (-not (Test-Path $JournalPath)) {
        return $summary
    }

    $lines = @(Get-Content -Path $JournalPath | Where-Object { $_.Trim() })
    if ($lines.Count -eq 0) {
        return $summary
    }

    $entries = @($lines | ForEach-Object { $_ | ConvertFrom-Json })
    [array]::Reverse($entries)

    foreach ($entry in $entries) {
        switch ($entry.Kind) {
            'edit' {
                try {
                    $changedFields = @(($entry.RequestJson | ConvertFrom-Json).PSObject.Properties.Name)
                    $restoreBody = ($entry.PreState | Select-Object -Property $changedFields | ConvertTo-Json -Compress -Depth 15)
                    & $script:FogRealInvokeFogApi -uriPath $entry.UriPath -Method 'PUT' -jsonData $restoreBody | Out-Null
                    $summary.Restored.Add("Reverted $($entry.UriPath) (fields: $($changedFields -join ', ')) back to its pre-run value") | Out-Null
                } catch {
                    $summary.FailedToRestore.Add("Could not revert $($entry.UriPath): $($_.Exception.Message). Original value was:`n$($entry.PreState | ConvertTo-Json -Depth 15 -Compress)") | Out-Null
                }
            }
            'create' {
                try {
                    & $script:FogRealInvokeFogApi -uriPath "$($entry.UriPath)/$($entry.CreatedId)/delete" -Method 'DELETE' | Out-Null
                    $summary.Restored.Add("Deleted test-created '$($entry.UriPath)' id $($entry.CreatedId)") | Out-Null
                } catch {
                    if ($_.Exception.Message -match '404|Not Found') {
                        # a test may have already deleted this itself as part of its own assertions - not a failure
                        $summary.Restored.Add("Test-created '$($entry.UriPath)' id $($entry.CreatedId) was already gone (likely deleted by the test itself)") | Out-Null
                    } else {
                        $summary.FailedToRestore.Add("Could not delete test-created '$($entry.UriPath)' id $($entry.CreatedId): $($_.Exception.Message)") | Out-Null
                    }
                }
            }
            'edit-untracked' {
                $summary.Unrevertable.Add("Edited $($entry.UriPath) but could not snapshot its pre-run value first ($($entry.Note)) - cannot auto-revert, check it manually") | Out-Null
            }
            'create-untracked' {
                $summary.Unrevertable.Add("Created via $($entry.UriPath) but the response had no id to clean up: $($entry.Result | ConvertTo-Json -Compress -Depth 10)") | Out-Null
            }
            'task' {
                $summary.Unrevertable.Add("Queued a real task via $($entry.UriPath) (id $($entry.Result.id)) - dispatched tasks (deploy/capture/snapin/WoL) have no per-task cancel and can't be auto-undone") | Out-Null
            }
            'delete' {
                if ($entry.PreState) {
                    $summary.Unrevertable.Add("Permanently deleted via $($entry.UriPath) - cannot be restored through the API. Original data was:`n$($entry.PreState | ConvertTo-Json -Depth 15 -Compress)") | Out-Null
                } else {
                    $summary.Unrevertable.Add("Permanently deleted via $($entry.UriPath) - cannot be restored through the API, and its data couldn't even be captured before deletion") | Out-Null
                }
            }
        }
    }

    return $summary
}

function ConvertTo-FogTestResultsMarkdown {
    <#
    .SYNOPSIS
    Formats a Pester -PassThru result as a published, human-readable test-results report.

    .DESCRIPTION
    Turns $result.Tests (from Invoke-Pester -Configuration $config where Run.PassThru is set)
    into the same "one checklist per source file" markdown shape previously hand-copied into
    docs/TestValidation.md, so that page can be refreshed from a real generated artifact instead
    of a manual paste. Says up front whether the run was mocked or against a real Fog server,
    since a green mocked run and a green -RealServer run mean different things.

    .PARAMETER Tests
    The flat Tests array off a Pester result object (Invoke-Pester -PassThru).

    .PARAMETER RealServer
    Whether this run was against a real Fog server (unmocked, journaled) rather than fixtures.

    .PARAMETER GeneratedAt
    Timestamp to stamp the report with. Pass this in rather than calling Get-Date internally, so
    the function stays pure/deterministic for testing - the caller (Invoke-FogApiTests.ps1) owns
    wall-clock time.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Tests,
        [switch]$RealServer,
        [Parameter(Mandatory = $true)]
        [string]$GeneratedAt
    )

    $total = $Tests.Count
    $passed = @($Tests | Where-Object Result -eq 'Passed').Count
    $failed = @($Tests | Where-Object Result -eq 'Failed').Count
    $mode = if ($RealServer) { 'against a real, configured Fog server (unmocked)' } else { 'mocked, with fixture data under Tests/Fixtures' }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# FogApi test results')
    $lines.Add('')
    $lines.Add("Generated $GeneratedAt - $mode.")
    $lines.Add('')
    $lines.Add("**$passed / $total** tests passed$(if ($failed -gt 0) { ", **$failed** failed" }).")
    $lines.Add('')

    $byFile = $Tests | Group-Object { Split-Path $_.ScriptBlock.File -Leaf } | Sort-Object Name
    foreach ($group in $byFile) {
        $lines.Add("### ``$($group.Name)`` ($($group.Group.Count) tests)")
        $lines.Add('')
        foreach ($test in $group.Group) {
            $mark = if ($test.Result -eq 'Passed') { '[x]' } else { '[ ]' }
            $duration = [math]::Round($test.Duration.TotalSeconds, 3)
            $suffix = if ($test.Result -ne 'Passed') { " - **$($test.Result)**" } else { '' }
            $lines.Add("- $mark ``$($test.ExpandedName)`` ($($duration)s)$suffix")
        }
        $lines.Add('')
    }

    return ($lines -join "`n")
}

function Update-FogRealServerValidationLedger {
    <#
    .SYNOPSIS
    Maintains the durable, source-controlled record of which examples have actually been
    exercised against a real Fog server, and when.

    .DESCRIPTION
    Unlike the coverage report or the test-results report (both regenerated wholesale on every
    run, from ephemeral TestResults/), this is a merge: it loads any existing ledger at
    LedgerPath, updates only the entries for tests that just ran under -RealServer (keyed on the
    test's Context/Describe grouping + its own name, so this works for the hand-written,
    non-data-driven tests in FogApi.RealServer.Tests.ps1), and leaves every other
    previously-recorded entry untouched. That's what makes it meaningful as a "documented list of
    what has been run against a real server" - a mocked run never touches it, and a targeted
    -RealServer run doesn't erase the record of everything else validated in a previous run.

    Intended to be committed to source control (see docs/RealServerValidation.md, rendered
    alongside it) so the history is reviewable in PRs, not just a local artifact.

    .PARAMETER LedgerPath
    Path to the JSON ledger file (the source of truth this function reads and merges into).

    .PARAMETER MarkdownPath
    Path to the rendered markdown page, fully regenerated from the merged ledger every call.

    .PARAMETER Tests
    The flat Tests array off a Pester result object, already filtered by the caller to
    FogApi.RealServer.Tests.ps1 (the only file with real, unmocked -RealServer results; the
    fixture-driven example suite and the coverage report never touch a real server).

    .PARAMETER RunDate
    Date to stamp updated entries with (an ISO date string). Passed in rather than computed here
    so this function stays pure/testable - the caller owns wall-clock time.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LedgerPath,
        [Parameter(Mandatory = $true)]
        [string]$MarkdownPath,
        [Parameter(Mandatory = $true)]
        [object[]]$Tests,
        [Parameter(Mandatory = $true)]
        [string]$RunDate
    )

    $ledger = [ordered]@{}
    if (Test-Path $LedgerPath) {
        $existing = @(Get-Content -Path $LedgerPath -Raw | ConvertFrom-Json)
        foreach ($record in $existing) {
            $ledger["$($record.Group)|$($record.Name)"] = $record
        }
    }

    foreach ($test in $Tests) {
        $group = if ($test.Path.Count -gt 1) { ($test.Path[0..($test.Path.Count - 2)] -join ' > ') } else { '(top level)' }
        $key = "$group|$($test.Name)"
        $ledger[$key] = [PSCustomObject]@{
            Group               = $group
            Name                = $test.Name
            Result              = "$($test.Result)"
            LastValidatedOnReal = $RunDate
        }
    }

    $ledgerDir = Split-Path $LedgerPath -Parent
    if ($ledgerDir -and -not (Test-Path $ledgerDir)) {
        New-Item -Path $ledgerDir -ItemType Directory -Force | Out-Null
    }
    $ledgerArray = @($ledger.Values | Sort-Object Group, Name)
    ($ledgerArray | ConvertTo-Json -Depth 5) | Set-Content -Path $LedgerPath

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Real-server validation history')
    $lines.Add('')
    $lines.Add('Which integration tests (Tests/FogApi.RealServer.Tests.ps1) have actually been run against a real, configured Fog server, and when they were last confirmed - maintained by `Update-FogRealServerValidationLedger`, merged in each time someone runs `.\Invoke-FogApiTests.ps1 -RealServer` and commits the result. A test missing from this page has never been run against a real server.')
    $lines.Add('')
    $byGroup = $ledgerArray | Group-Object Group | Sort-Object Name
    foreach ($group in $byGroup) {
        $lines.Add("## $($group.Name)")
        $lines.Add('')
        foreach ($record in $group.Group) {
            $mark = if ($record.Result -eq 'Passed') { '[x]' } else { '[ ]' }
            $lines.Add("- $mark ``$($record.Name)`` - last validated $($record.LastValidatedOnReal), $($record.Result)")
        }
        $lines.Add('')
    }

    $markdownDir = Split-Path $MarkdownPath -Parent
    if ($markdownDir -and -not (Test-Path $markdownDir)) {
        New-Item -Path $markdownDir -ItemType Directory -Force | Out-Null
    }
    ($lines -join "`n") | Set-Content -Path $MarkdownPath

    return $ledgerArray
}

Export-ModuleMember -Function Get-FogExampleCase, Get-FogMockResponse, Test-FogExpectedSubset, Register-FogApiMock, Get-FogParameterSetCoverage, ConvertTo-FogCoverageMarkdown, Initialize-FogRealServerJournal, Restore-FogRealServerState, ConvertTo-FogTestResultsMarkdown, Update-FogRealServerValidationLedger
