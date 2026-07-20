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

At test time, each annotated example is actually run, with the module's one HTTP seam (`Invoke-FogApi`) mocked using small fixture files under `Tests/Fixtures/`, and the real result is checked against the documented `Expected output:` - as a *subset* match, so a documented example only needs to call out the fields that matter, not every property a Fog host object happens to have.

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

# run the same examples unmocked against a real, already-configured Fog server
# (note: this will really create/modify/message objects on that server)
.\Invoke-FogApiTests.ps1 -RealServer
```

See `Tests/FogApi.TestHelpers.psm1` for the parsing/mocking helpers if you want to extend the suite - `Get-FogExampleCase`, `Get-FogMockResponse`, `Test-FogExpectedSubset`, and the coverage-reporting functions are all documented there.
