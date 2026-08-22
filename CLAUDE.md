# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

FogApi is a PowerShell module (client SDK) that wraps the REST API of the [FOG Project](https://fogproject.org) (open-source PXE imaging/deployment platform), letting sysadmins do via PowerShell everything the FOG web GUI does — host management, imaging tasks, snapins, groups, inventory, WOL, etc. Full cmdlet docs: https://fogapi.readthedocs.io/en/latest/

## Build, Test, and Release Commands

- **Dev build (module only):** `Import-Module .\BuildHelpers.psm1; .\invoke-modulebuild.ps1` — combines `Public/`, `Private/`, `Classes/*.ps1` into `_module_build/FogApi/FogApi.psm1` and updates the manifest's `FunctionsToExport`.
- **Full build (docs + module + version bump):** `.\build.ps1` (requires the `PlatyPS` module). Params: `-releasenote`, `-buildPth`, `-major`, `-buildMkdocs`, `-noMkdocsPause`, `-NoVerStep`. Generates docs from comment-based help, bumps the version, updates `docs/ReleaseNotes.md`.
- **Chocolatey package build:** `.\build-choco.ps1` (uses `chocoTemplate/`).
- **Docs site:** MkDocs (`mkdocs.yml`, Python deps in `docs/requirements.txt`), built locally via `build.ps1 -buildMkdocs` or on Read the Docs (`.readthedocs.yml`).
- **CI:** `.github/workflows/build-test.yml` runs `.\invoke-modulebuild.ps1` then `Test-ModuleManifest` + `Import-Module` as a smoke test on `windows-latest` for PRs to master. `.github/workflows/tag-and-release.yml` re-runs that build, then `build.ps1`, and publishes to PSGallery + Chocolatey on merge to master.
- **Linting:** none configured (no PSScriptAnalyzer settings file exists).
- **Tests:** Pester, run with `./Invoke-FogApiTests.ps1` (`-CI` for the CI shape, `-Function <name>` to scope a run). Mocked against `Tests/Fixtures/` by default — that is the CI gate. `-RealServer` additionally runs `Tests/FogApi.RealServer.Tests.ps1` against whatever server `api-settings.json` points at, journaling every mutating call and reverting it afterwards.

## Architecture

Everything lives under `FogApi/`:
- `FogApi.psm1` — module entry point; dot-sources every script in `Public/` and `Private/` and exports the public function names + aliases.
- `FogApi.psd1` — manifest; declares `FunctionsToExport`/`AliasesToExport`. **When adding a new public function with an alias, update both the `[Alias(...)]` attribute in the `.ps1` file and the manifest lists — they are not auto-synced.**
- `Public/*.ps1` — one file per exported cmdlet (~60 total), each with full comment-based help (`.SYNOPSIS`/`.DESCRIPTION`/`.PARAMETER`/`.EXAMPLE`) that feeds PlatyPS-generated docs in `docs/commands/` and `docs/en-us/`.
- `Private/*.ps1` — internal helpers, not exported.
- `lib/settings.json` — placeholder settings template (not real config; see Configuration below).

**Request flow** (e.g. deploying an image) is a 3-layer chain:
1. Business-logic cmdlets in `Public/`, e.g. `Send-FogImage.ps1`, `New-FogHost.ps1`, `Get-FogHost.ps1` — build FOG-specific JSON payloads and handle version-dependent shape differences.
2. Generic CRUD wrappers, also in `Public/`: `Get-FogObject.ps1`, `New-FogObject.ps1`, `Update-FogObject.ps1`, `Remove-FogObject.ps1`, `Find-FogObject.ps1` — map a `-type`/`-coreObject` pair to a REST verb + URI path (e.g. `host/1234/edit`).
3. `Public/Invoke-FogApi.ps1` — the single HTTP choke point. Loads settings, builds the `fog-api-token`/`fog-user-token` headers and URI, calls `Invoke-RestMethod` (falling back to `Invoke-WebRequest` on failure).

Other architecturally important pieces:
- `Private/Set-DynamicParams.ps1` + `Private/Get-DynmicParam.ps1` — implement `DynamicParam` blocks giving `-coreObject`/`-coreTaskObject`/`-coreActiveTaskObject` tab-completion; the valid set of FOG object names varies by FOG server version.
- `Public/Get-FogVersion.ps1` + `Public/Test-FogVerAbove1dot6.ps1` — detect FOG 1.5 vs 1.6+ to branch JSON payload construction and available core objects throughout the codebase (FOG 1.6 added a response `data` wrapper).
- `Public/Add-FogResultData.ps1` — normalizes that FOG 1.5/1.6 response-shape difference by ensuring a `.data` property always exists.

There is no local database, ORM, or migrations — the FOG server owns the real data (external MySQL). This module is a pure HTTP client; "models" are ad hoc JSON/hashtables built per-cmdlet, shaped per FOG's own API conventions (https://news.fogproject.org/simplified-api-documentation/).

## Configuration

Config is a local JSON file per OS user, **not** environment variables:
- Path: Windows `%APPDATA%\FogApi\api-settings.json`; Linux/Mac `~/.FogApi/api-settings.json` (resolved in `Public/Get-FogServerSettingsFile.ps1`).
- `Public/Get-FogServerSettings.ps1` bootstraps the file from the `lib/settings.json` template if missing, sets restrictive file permissions, and is called by `Invoke-FogApi.ps1` on **every single API call** (no caching).
- `Public/Set-FogServerSettings.ps1` (supports `-interactive`) writes settings; if a required value is still a placeholder, it opens the file in an OS-appropriate editor (notepad/code/vi/nano/TextEdit) and aborts, asking the user to re-run.
- Auth = two static tokens sent as headers on every request: `fog-api-token` (server-wide, from FOG's API System settings) and `fog-user-token` (per-user).
- `Public/Enable-FogApiHTTPS.ps1` / `Disable-FogApiHTTPS.ps1` toggle the stored server URL between `http://` and `https://`.

## Versioning

Scheme is `{Year}{Month}.{Major}.{Revision}` (e.g. `2208` = August 2022); bumped automatically by `build.ps1`.

## Commit authorship

Commits are **authored by the human running the session and co-authored by the
agent**, never the other way round. A fresh cloud session starts with no git
identity, so this has to be set per clone, every time:

```bash
git config user.name  "<the human's name>"
git config user.email "<the human's git email>"
```

Resolving who that is, in order:

1. An existing `git config user.email` in the clone or a global config — use it.
2. The account that owns the session. Its GitHub noreply address
   (`<id>+<login>@users.noreply.github.com`) is what this history already uses;
   `git log --format='%an <%ae>'` shows the form for a given contributor.
3. Otherwise ask. Do not guess a variant of a name seen elsewhere.

Never fall back to `Claude <noreply@anthropic.com>` as the **author**. It goes
in the trailer instead:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```

No model name in the trailer, and no model identifier anywhere in a commit
message, PR title or body, or code comment.

If commits were already made under the wrong author, reauthor rather than
leaving it — on an unmerged branch belonging to the same author:

```bash
git rebase <base> --exec "git commit --amend --no-edit --author='<name> <email>' --quiet"
git push --force-with-lease origin <branch>
```

Only reauthor commits the agent made in this session. Never rewrite another
contributor's commits, and never force-push a branch that has already merged.

## Git Flow

Always branch from `dev`, not `master`. `dev` is merged into `master` via PR, which is what triggers `tag-and-release.yml` (version bump, docs build, PSGallery/Chocolatey publish). Feature/fix branches should target `dev` in their pull requests.
