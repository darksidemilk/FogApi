# Context: Complete API Coverage & Python Port Groundwork

Working document for the multi-phase effort to give FogApi a helper function for every FOG API
operation, driven by a machine-readable spec so a future Python port is a second emitter rather than
a second implementation.

Tracking issue: **[#61](https://github.com/darksidemilk/FogApi/issues/61)**

---

## Why

FogApi's 66 public functions were written demand-driven — a cmdlet exists because someone needed it.
`host` has a rich family while ~40 of FOG's ~50 API object classes have no typed cmdlet at all.
Anyone wanting to list printers or edit a storage node has to know to reach for
`Get-FogObject -type object -coreObject printer` and guess the JSON payload shape.

Goal: a complete, discoverable library where you tab-complete instead of digging. The existing
3-layer chain is unchanged:

```
Get/Update/Remove-Fog<Noun>  ->  Get/New/Update/Remove/Find-FogObject  ->  Invoke-FogApi
   (typed, new)                     (generic L1)                            (transport)
```

Secondary driver: a synced Python port for Linux users who won't install PowerShell Core. One spec
generates both, keeping them in sync by construction, and doubles as built-in API documentation for
anyone building a FOG tool in any language.

---

## Status

| Phase | State | Branch |
|---|---|---|
| **0 — Paging** | **Done, awaiting review** | `fix/fog16-paging-truncation` |
| 0.3 — Layer-violation refactor | Not started | `refactor/l1-crud-standardization` |
| 0.5 — ValidateSet additions + version caching | Not started | `fix/dynamic-param-classes` |
| 1 — Spec + generator + coverage matrix + printer pilot | Not started | `feat/api-spec-generator` |
| 2-5 — Generate Tiers 1-3, hand-write fixed routes | Not started | one branch per tier |
| 6 — Test rebuild around language-neutral corpus | Not started | |
| 7 — Real-server CI + fog-workflows release gate | Blocked on FOGProject org move | |
| 8 — Python port | Not started | |

**Branching rule:** every phase branches from `dev` and PRs back into `dev`. Never branch from or PR
into `master` — `dev`->`master` is the separate PR that triggers `tag-and-release.yml`.

### Phase 0 — what shipped

Commit `f418c24` on `fix/fog16-paging-truncation`.

FOG 1.6 commit `dd40b7d0e` (2026-08-12) capped any list request carrying no `start` param at
`MAX_ROWS = 10000`. FogApi never sent paging params, so **every list cmdlet silently truncated at
10,000 rows** against a current 1.6 server — no error, no warning. Sweep functions like
`Repair-FogSnapinAssociations` were operating on a partial view.

- `FogApi/Private/Get-FogPagedResult.ps1` (new) — walks the pages
- `Get-FogObject` — list branch now always sends `?start=N&length=N`, follows `nextUrl`;
  adds `-First`, `-Skip`, `-PageSize`, `-NoAutoPage`
- `Tests/Get-FogPagedResult.Tests.ps1` (new) — 15 tests asserting the **request sequence**
- `Add-FogResultData` — fixed the multi-NoteProperty array case
- `FogApi.psd1` — added the missing `Get-PendingMacsForHost` alias export
- `Tests/FogApi.TestHelpers.psm1` — strips query string before fixture lookup

Suite: 69 -> 85 passing, 0 failing.

### How to review/test Phase 0

```powershell
git checkout fix/fog16-paging-truncation
.\Invoke-FogApiTests.ps1                        # expect 85 passed / 0 failed / 17 skipped
Import-Module .\BuildHelpers.psm1 -Force
.\invoke-modulebuild.ps1                        # expect 66 functions / 24 aliases
Test-ModuleManifest .\_module_build\FogApi\FogApi.psd1
```

Against a real server, the thing worth confirming by hand — a table with more than 10,000 rows now
returns everything:

```powershell
(Get-FogObject -type object -coreObject host).data.Count    # vs. the web UI's host count
Get-FogObject -type object -coreObject host -First 5 -Verbose  # verbose shows one request only
Get-FogHosts | Measure-Object                                # unchanged call site, now complete
```

Also worth a real-server sanity check that nothing regressed on the unpaged paths:
`Get-FogHost -hostID <id>`, `Get-FogActiveTasks`, and
`Find-FogObject -coreObject unisearch -stringToSearch <term>`.

---

## Verified server facts

Researched from `fogproject` (1.5, `dev-branch`) and `working-1.6`. Recorded so a future session
doesn't re-derive them.

### Paging (1.6 only)

- **Params are `length` (page size) and `start` (offset), query string.** No limit/offset/page.
  Folded in by `Route::listem()` (`route.class.php:1035-1057`).
- **`?start` alone does nothing** — the fold only fires when `length` is present.
- **The cap triggers on absence of `start`, not `length`** (`fogmanagercontroller.class.php:269-332`).
  Capped paths: no `start`, `length == -1`, or negative `length`.
- **Envelope:** `draw, recordsTotal, recordsFiltered, truncated, data[], _lang, recordsReturned,
  firstUrl, prevUrl, nextUrl, lastUrl`. Also emitted as an RFC 5988 `Link:` header.
- **Terminate on `nextUrl` only.** `recordsFiltered` is rewritten to the post-scoping count for
  site-restricted users by `filtersitemassdata.hook.php:145-152` (a floor, not a total).
  `truncated` is only set when the *server* imposed the cap, which never happens once we send our
  own params.
- **Advance by rows returned, not requested** — `?expand` forces `length = EXPAND_MAX_ITEMS (2500)`
  (`route.class.php:142`), so a short page does not mean "done".
- **`names` and `ids` routes have no LIMIT at all** — unbounded, uncapped, no envelope. They stay the
  cheap "enumerate everything" escape hatch and need no pager.
- Ordering is deterministic (`ORDER BY <orderby|id> ASC`, GH-956), so paging won't skip/repeat.
- **1.5 has none of this** — no `limit()`, no `complex()`, no `MAX_ROWS`, no `paginate`. Envelope is
  `{count, <classname>s[]}` and lists are unbounded.

### Route shapes

Generic, per class: `list` `{class}` GET · `get` `{class}/{id}` GET · `search`
`{class}/search/{item}` GET · `names` `{class}/names/{where}` GET · `ids`
`{class}/ids/{where}/{field}` GET · `create` `{class}` POST · `update` `{class}/{id}/edit` PUT ·
`delete` `{class}/{id}/delete` DELETE. 1.6 adds `count` and `join`; 1.5 has `listdetails`.

Tasking: `task` `{class}/{id}/task` POST · `cancel` `{class}/{id}/cancel` DELETE · `active`
`{class}/current` GET. **WOL is not a route** — it's `task` with `wol: true` / `taskTypeID 14`.

Fixed routes — both: `system/status`, `system/info`, `system/export`, `snapin/createwithfile`,
`storagegroup/{id}/uploadsnapinfiles`. 1.6 only: `unisearch/{item}/{limit}`, `search/{item}/{limit}`,
`availablekernels`, `availableinitrds`, `bandwidth/{dev}`, `pendingmacs`, `whoami`, `logfiles/{id}`,
`settings/cache`, `settings/cache/flush`, `settings/cache/refresh`.

### unisearch

`/unisearch/{item}/{limit}` — `{limit}` is a **per-entity-type** row cap appended to each per-class
SELECT, so `/unisearch/foo/5` returns up to 5 hosts *and* 5 images *and* 5 groups. It never calls
`paginate()`, so there is no `nextUrl` and no way to page past it. **This is a different mechanism
from `start`/`length`** — `Find-FogAll` must keep a distinct `-limit`, not reuse `-First`.

### ValidateSet gaps in `Private/Get-DynmicParam.ps1`

Missing from the 1.6 list: `filedeletequeue`, `role`, `rolepermission`, `roleuserassociation`,
`roleusergroupassociation`, `usergroup`, `usergroupmember`, `sitehostassociation`.
Wrong but **deliberately not removed**: `user`/`setting` in the 1.5 list, `siteassociation`,
`unisearch` (not a class). Removing entries breaks callers; adding never does.

### Version probe overhead (found in Phase 0)

`Get-DynmicParam` calls `Get-FogVersion` while binding `-coreObject`, so **every** call that binds a
dynamic param issues `GET system/info` first, and when that returns no version it *also* issues
`GET service/getversion.php`. A one-request cmdlet call costs up to three round-trips, and this
scales with every generated cmdlet. `Tests/Get-FogPagedResult.Tests.ps1` has to filter these probes
out to assert on real requests. Fixing this is Phase 0.5 and is now load-bearing, not a nicety.

---

## Locked decisions

- **Approved verbs only.** Audited: every proposed and existing function verb passes `Get-Verb`. The
  only unapproved verbs are in aliases (`Capture-FogImage`, `Deploy-FogImage`) — the sanctioned use.
  Generator validates and fails the build on a miss.
- **Plural list nouns stay** (`Get-FogHosts`). Violates `PSUseSingularNouns`; matches six existing
  functions and costs zero breaking changes. Add `PSScriptAnalyzerSettings.psd1` recording the
  deliberate exception.
- **No breaking changes.** Better name becomes the function, old name becomes an alias, both go in
  `FunctionsToExport` *and* `AliasesToExport`.
- **Python names are mechanically derived, not byte-identical.** PEP 8 wins:
  `Get-FogHost` -> `get_fog_host()`. Spec stores `verb`/`noun` separately so both emitters derive.
- **Dynamic params: additive only.** Never remove a ValidateSet entry. Own PR, own regression test.
- **`Find-FogObject` and the unisearch path are not modified.** New capability arrives as
  `Find-FogAll` alongside it.
- **Every cmdlet routes through L1.** Only Tier 5 fixed-route cmdlets may call `Invoke-FogApi`
  directly, because those endpoints have no L1 representation.
- **Pipeline contract:** every cmdlet's primary object param accepts an id, an object, or a
  collection of either, via a shared `Resolve-FogObjectId`. The polymorphic-input half ports to
  Python; the `|` syntax half does not and should not be emulated there.

---

## Known traps

- **Stale source manifest.** `invoke-modulebuild.ps1` updates only the `_module_build` copy of
  `FogApi.psd1`, never the source. New functions are invisible to the test suite until the source
  `FunctionsToExport` is rewritten. This already bit once (`Get-PendingMacsForHost`, fixed in Phase 0).
- **`FogApi.psm1:4` globs `Public/*.ps1` non-recursively** — a `Generated/` subfolder would be
  silently skipped at import. Generated files therefore go flat in `Public/`.
- **One `<#...#>` block per file, help block first.** Both build scripts strip comments via
  `IndexOf('<#')`/`IndexOf('#>')` — first occurrence only.
- **`[Alias()]` must be on the line immediately after `[CmdletBinding(...)]`** — `Get-AliasesToExport`
  indexes that exact line and silently drops aliases declared elsewhere.
- **`Tests/FogApi.Examples.Tests.ps1` uses a hardcoded 46-name inclusion list** — new functions get
  zero tests, silently. Invert to manifest-driven-minus-exclusions (Phase 1).
- **`Get-FogMockResponse` throws on unmapped paths** and is a hand-maintained `switch -regex`.
  Phase 0 taught it to strip query strings; Phase 1 should make lookup convention-based.
- **`invoke-modulebuild.ps1:75` references `$docsPth`**, never defined, so the built module ships
  with no help content. Non-terminating, so CI passes today.

---

## Next session, start here

1. Confirm Phase 0 is merged to `dev`.
2. `git checkout dev && git pull && git checkout -b refactor/l1-crud-standardization`
3. Phase 0.3 scope:
   - `Start-FogSnapins.ps1:62,72` -> `Get-FogObject -type objectactivetasktype -coreActiveTaskObject task`
     and `Remove-FogObject -type objecttasktype -coreTaskObject task -IDofObject $id`
   - `Remove-UsbMac.ps1:100,125` -> `Update-FogObject` / `Remove-FogObject` on `macaddressassociation`
   - Extract `Get-FogSystemInfo`; `Get-FogVersion` calls it (stays direct — fixed route, not CRUD)
   - **`Set-FogInventory` is incorrect, not just a layer violation.** It POSTs `inventory/new`
     unconditionally, so every call creates a duplicate inventory row. Line 43 is dead code, line 42
     hardcodes `-verbose`, and lines 31-33 let `$_` clobber a bound `-hostObj`. Fix: resolve the
     host's existing inventory id, then `Update-FogObject` or `New-FogObject` as appropriate. Keep
     the name, params, and pipeline binding. Confirm inventory-per-host cardinality on a real server
     for both 1.5 and 1.6 first. Behavior change — call out in release notes.
   - Delete the dead commented-out `Invoke-FogApi` lines in `Get-FogHostAssociatedSnapins.ps1` and
     `Set-FogSnapins.ps1`
