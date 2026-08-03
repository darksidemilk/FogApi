# Contributing

Thanks for taking an interest in improving FogApi! This page covers how the branching/release flow works and how the Pester test suite is organized, so you know what to expect from a PR.

## Git flow

- Always branch from `dev`, not `master`.
- Feature/fix branches target `dev` in their pull requests.
- `dev` gets merged into `master` via PR, and that merge is what triggers [`tag-and-release.yml`](https://github.com/darksidemilk/FogApi/blob/master/.github/workflows/tag-and-release.yml) - it bumps the module version, rebuilds the docs, and publishes to the PowerShell Gallery and Chocolatey. **Only `dev` is allowed to merge into `master`** - a PR into `master` from anywhere else fails the `enforce-dev-to-master` check in `build-test.yml`.
- Every pull request into `master` or `dev` runs [`build-test.yml`](https://github.com/darksidemilk/FogApi/blob/master/.github/workflows/build-test.yml), which builds the module as a smoke test and runs the Pester suite described below. This only validates (build succeeds, tests pass) - it has no publish/release side effects, those only happen via `tag-and-release.yml` on a merge to `master`.

## How the tests work

There's no separate suite of hand-written test files to keep in sync with the code - the Pester tests are generated directly from the same `.EXAMPLE` blocks in each function's comment-based help that already back the [command docs](commands/index.md) on this site. A function's example can carry an `Expected output:` marker in its remarks (the descriptive text after the example command, not the command itself):

```
.EXAMPLE
Get-FogHost -hostName MeowMachine

This would return the fog details of a host named MeowMachine in your fog instance

Expected output:
{ "name": "MeowMachine", "id": 42 }
```

The `Expected output:` payload is plain JSON, not a PowerShell object literal - that's on purpose, so the test runner can parse it with `ConvertFrom-Json` instead of evaluating arbitrary code. It's read via PowerShell's native `Get-Help -Full`, not the generated markdown, so it isn't affected by PlatyPS's limitation that example *code* has to stay on a single line - only the code line has that restriction; the remarks underneath it (including the `Expected output:` block) can be as many lines as you like.

At test time, each annotated example is actually run, with the module's one HTTP seam (`Invoke-FogApi`) mocked using small fixture files under `Tests/Fixtures/`, and the real result is checked against the documented `Expected output:` - as a *subset* match, so a documented example only needs to call out the fields that matter, not every property a Fog host object happens to have. One exception to "match exactly": any property whose name ends in `id` (`id`, `hostID`, `groupID`, `snapinID`, ...) only has to look like a valid id (a non-negative integer) rather than equal the fixture's specific hardcoded value - harmless leniency that costs nothing against fixtures (which already return a valid-looking id), kept mainly so the assertion logic isn't needlessly brittle.

This example-driven suite always runs mocked, including in CI - it is **not** run against a real Fog server. Its `Expected output:` annotations are illustrative, fixed values authored to match the fixtures (a specific version string, a specific settings list, host id `42`); a real server's actual data will essentially never match them even when a call fully succeeds, and most examples also reference fixture-only ids/names that plainly won't exist on any given real server. See `-RealServer` below for how real-server validation is actually done instead.

### The standing goal: one annotated example per parameter set

The target this suite is working towards is **one annotated example for every parameter set of every function** - not just one example per function. A function like `Get-FogHost` has three parameter sets (`searchTerm`, `byID`, `serialNumber`); ideally each of those has its own example demonstrating it, with an `Expected output:` block. This is a standing, evolving goal - as functions or parameter sets are added, coverage should grow to match.

To help track it, every test run produces an informational coverage report (`TestResults/coverage-report.md` locally, uploaded as the `parameter-set-coverage-report` artifact in CI) that reflects on each function's real parameter sets and cross-references them against the examples that exist, flagging which sets have no example at all versus which have an example that just isn't annotated yet. **This report is purely informational - it never fails a build or blocks a PR.** Outside contributors aren't expected to add `.EXAMPLE`/`Expected output:` annotations themselves; maintainers use the report to find and backfill gaps after the fact. A recent snapshot of both the test results and this coverage report is published on the [Testing Validation](TestValidation.md) page.

### Intentional gaps in the coverage report

A handful of functions will always show up in the coverage report as missing an annotated example, and that's expected rather than backlog:

- **Windows-local system operations that don't call the Fog API at all**, so mocking `Invoke-FogApi` gives them nothing to verify: `Mount-WinEfi`, `Dismount-WinEfi`, `Get-WinEfiMountLetter`, `Get-WinBcdPxeID`, `Set-WinToBootToPxe`, `Install-FogService`, `Get-FogSecsSinceEpoch` (time/timezone-dependent).
- **Local config/file/registry helpers**, also with no HTTP call to mock: `Get-FogServerSettingsFile`, `Get-FogServerSettings`, `Set-FogServerSettings`, `Set-FogServerSettingsFileSecurity`, `Disable-FogApiHTTPS`, `Enable-FogApiHTTPS`, `Get-FogLog`, `Resolve-HostID`.
- **Examples that depend on the identity of the machine actually running the test** (the current computer's hostname/UUID/MAC via `Get-CimInstance`/`Get-NetAdapter`), which can't be pinned to a fixture: `Get-FogHost`'s parameterless example, and any other function's example that relies on it (e.g. `Get-FogHostMacs`'s `byHostObject` set, `Reset-HostEncryption`'s `-restartSvc` example, `Send-FogWolTask`'s AD-lookup example, `Get-LastImageTime`'s `bySN`/interactive example).
- **`Invoke-FogApi` itself** - it's the thing being mocked for every other function, so it's covered by its own dedicated seam test (`Tests/Invoke-FogApi.Tests.ps1`) instead of an `Expected output:` annotation.
- **The generic CRUD wrappers' own bare invocation** (`Get-FogObject`, `New-FogObject`, `Update-FogObject`, `Remove-FogObject`, `Find-FogObject`) - their `-type`/`-coreObject` dynamic parameters mean real coverage comes from the dozens of business-logic functions that call through them (`Add-FogHostMac`, `Get-FogGroups`, etc.), not from an example on the wrapper itself.

If you're evaluating the report and a gap doesn't match one of these categories, it's a real gap worth backfilling.

### Running the tests locally

```powershell
# fast, mocked - no Fog server needed
.\Invoke-FogApiTests.ps1

# scope to specific functions while you're working on them
.\Invoke-FogApiTests.ps1 -Function Get-FogHost, New-FogHost

# also run the real-server integration suite against a real, already-configured Fog server
# (note: this will really create/modify/message objects on that server - see below)
.\Invoke-FogApiTests.ps1 -RealServer
```

### `-RealServer`: a separate, hand-written integration suite

`-RealServer` does **not** run the fixture-driven example suite above against a real server - it additionally runs `Tests/FogApi.RealServer.Tests.ps1`, a small, hand-written integration suite that is not derived from doc examples at all. Early iterations tried making the *same* example-derived tests run unmocked against a real server, but that doesn't hold up: an example like `Get-FogVersion` has an `Expected output:` of the literal string `"1.6.0"`, and `Get-FogSettings`/`Get-FogHosts`/`Get-FogModules` expect the fixtures' exact hardcoded settings/host/module lists - a real server's actual version and inventory will essentially never match those specific values even when the call fully succeeds, and separately, most examples reference fixture-only ids/names (`-hostID 42`, `-groupID 7`) that won't exist on any given real server either. Chasing that with more leniency doesn't scale - what a real server actually validates should be a *contract* (did the round-trip work, is the shape right), not "does it match this illustrative example."

So `FogApi.RealServer.Tests.ps1` instead:

- dynamically creates its own real, uniquely-named test host and group at the start of the run (never assumes fixture ids/names like `42`/`MeowMachine`/`7` already exist on your server), and works with whatever real ids the server actually assigns them;
- asserts real round-trip contracts using those real objects - e.g. `Update-FogObject` changes a field and `Get-FogHost` reflects it back; `Add-FogHostGroup` associates the host and `Get-FogHostGroup` shows it; `Set-FogSetting`-style edits are exercised through the same safety net rather than an isolated doc example;
- checks read-only calls (`Get-FogSettings`, `Get-FogModules`, `Get-FogVersion`, ...) structurally (right fields, right types) rather than for a specific value, since those values belong to whoever owns the real server being tested against, not to this suite.

It's entirely skipped (shown as `Skipped`, not run) unless `-RealServer` is passed.

### `-RealServer` safety net

Whether the mutation came from the integration suite's own setup or from one of its assertions, `Invoke-FogApi` is replaced with a recording passthrough (`Invoke-FogRealServerCall` in `Tests/FogApi.TestHelpers.psm1`) that still makes the real call, but journals every mutating one (to `.\TestResults\realserver-journal.ndjson` by default, see `-RealServerJournalPath`) as it happens. Once the run finishes, `Restore-FogRealServerState` walks that journal in reverse and:

- reverts every edited value (e.g. a Fog setting, or a field on the test host) back to what it was before the run - and only the specific fields that were actually changed, not the whole object, so this can't trip Fog's own quirks around resending an unchanged field (like a host's name);
- deletes every object the run created (the dynamically-created test host/group included);
- reports anything that genuinely can't be undone through the API instead of silently dropping it - a dispatched task (deploy/capture/snapin push/WoL has no per-task cancel), a permanently deleted object, or an edit whose pre-state couldn't be captured. These show up as `[CANNOT AUTO-REVERT]` warnings at the end of the run, with the original data included where available so it can be restored manually if needed.

The journal is written to disk as it happens (not just held in memory), so even if the run crashes or is killed outright, the file left behind still records exactly what changed and what it was before - nothing is lost, worst case it just isn't auto-reverted for you. Because the integration suite creates and owns the objects it mutates (rather than guessing at an existing production host's id), even the "can't be auto-undone" cases (a dispatched task) land on a throwaway test host, not on real hardware someone else depends on.

### Test results and real-server validation history

Every run of `Invoke-FogApiTests.ps1` also writes a published-quality markdown test-results report (`TestResults/test-results.md` by default, see `-TestResultsReportPath`) - the same "one checklist per source file, pass/fail and duration per test" shape previously hand-copied into the [Testing Validation](TestValidation.md) page, now generated for real instead.

`-RealServer` runs additionally update a durable, source-controlled ledger of which `FogApi.RealServer.Tests.ps1` tests have actually been validated against a real Fog server and when (`docs/RealServerValidation.json`, rendered as [`docs/RealServerValidation.md`](RealServerValidation.md), see `-RealServerValidationPath`). Unlike the reports above, this one is a *merge*, not a wholesale regeneration - it's meant to be committed, so the commit history of that file is itself a reviewable record of what's been confirmed against a live server over time. A test that's never appeared in that file has never been run against a real server.

See `Tests/FogApi.TestHelpers.psm1` for the parsing/mocking/real-server helpers if you want to extend either suite - `Get-FogExampleCase`, `Get-FogMockResponse`, `Test-FogExpectedSubset`, `Initialize-FogRealServerJournal`, `Register-FogApiMock`, `Restore-FogRealServerState`, `ConvertTo-FogTestResultsMarkdown`, `Update-FogRealServerValidationLedger`, and the coverage-reporting functions are all documented there.
