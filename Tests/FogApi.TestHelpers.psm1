#
# Shared helpers for the FogApi Pester suite.
# Not a *.Tests.ps1 file, so Pester does not auto-discover it - it is
# explicitly imported by the test files and by Invoke-FogApiTests.ps1.
#
# THE MOCKED HALF IS GONE, DELIBERATELY.
#
# There used to be a fixture-backed fake of the whole API: 106 canned JSON
# responses under Tests/Fixtures, a Get-FogMockResponse that matched a route to
# one of them, and 489 tests driven from the Expected output: blocks in each
# function's help. It asserted that the module still produced the shape somebody
# had written down, which is not the same thing as the shape the server sends,
# and it drifted the moment either side moved.
#
# It also had a structural failure mode that hit twice: a new cmdlet with no
# fixture failed the suite for a reason that said nothing about the change.
#
# What replaced it is testing against a real FOG server, with the journal below
# as the safety net. What remains here is the machinery for that, plus the
# coverage report, which never faked anything.
#
# Nothing in this file fabricates a server response any more. Please keep it
# that way -- a fixture is a snapshot of a belief, and beliefs go stale
# silently.
#


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

Export-ModuleMember -Function Get-FogParameterSetCoverage, ConvertTo-FogCoverageMarkdown, Initialize-FogRealServerJournal, Restore-FogRealServerState, ConvertTo-FogTestResultsMarkdown, Update-FogRealServerValidationLedger
