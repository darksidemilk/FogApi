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
- **Tests:** none implemented yet — `Tests/placeholder.md` notes Pester tests are planned but don't exist. The only current validation is the CI build-test workflow (module manifest + import smoke test); there is no single-test invocation pattern to follow yet.

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
