# Context: Complete API Coverage & Multi-Language Port Groundwork

Working document for the multi-phase effort to give FogApi a helper function for every FOG API
operation, driven by a machine-readable spec so the Python and bash ports are additional *emitters*
rather than additional *implementations*.

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

Secondary driver: synced **Python and bash** ports for Linux users who won't install PowerShell Core.
One spec generates all three, keeping them in sync by construction, and doubles as built-in API
documentation for anyone building a FOG tool in any language.

The bash target is not redundant with Python. **FOS ships no Python and no PHP** —
`BR2_PACKAGE_PYTHON3 is not set` across all three arch configs — but does ship bash, curl, jq and
openssl. Inside the imaging environment, where FOG's own automation runs, bash is the only one of the
three that can execute at all.

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
| 8 — Python + bash ports | Not started | Python first within the phase |

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
- **Port names are mechanically derived, not byte-identical.** Each target follows its own
  community's convention; the spec stores `verb` and `noun` separately so every emitter derives from
  the same source rather than munging another emitter's output. One rule, four renderings:

  | Spec | PowerShell | Python | Bash function | Bash CLI |
  |---|---|---|---|---|
  | `{Get, FogHost}` | `Get-FogHost` | `get_fog_host()` | `getFogHost` | `fogapi get-fog-host` |

  Bash uses camelCase because that is FOG's own bash house style — `working-1.6`'s
  `lib/common/functions.sh` and `bin/*.sh` define 88 camelCase functions (`installPackages`,
  `backupDB`, `_requestNodeCert`) against 25 all-lowercase.
- **Dynamic params: additive only.** Never remove a ValidateSet entry. Own PR, own regression test.
- **`Find-FogObject` and the unisearch path are not modified.** New capability arrives as
  `Find-FogAll` alongside it.
- **Every cmdlet routes through L1.** Only Tier 5 fixed-route cmdlets may call `Invoke-FogApi`
  directly, because those endpoints have no L1 representation.
- **Pipeline contract:** every cmdlet's primary object param accepts an id, an object, or a
  collection of either, via a shared `Resolve-FogObjectId`. The polymorphic-input half ports to
  Python and bash; the `|` syntax half does not and should not be emulated in either.
- **Bash requires `jq`,** detected explicitly with a clear error naming the package. No sed/grep
  JSON fallback. See the bash section below.

---

## Bash port facts (Phase 8)

Researched from `fos`, `fogproject` and `working-1.6`. Recorded so the emitter doesn't have to
re-derive them.

**No prior art.** Zero shell code in any FOG repo calls the REST API. FOS talks only to the legacy
non-REST `service/*.php` endpoints — form-POST in, plain-text out — parsed by literal string compare
(`[[ $res != "##@GO" ]]`, `[[ $servercaps != *mclvm* ]]`). FOG ships no host/image management CLI at
all; `bin/` is installer and maintenance only.

**Dependency matrix:**

| Environment | bash | curl | jq | php-cli | python3 |
|---|---|---|---|---|---|
| FOS | yes | yes | yes | no | **no** |
| FOG 1.6 server | yes | yes | yes (installer adds it) | yes | varies |
| FOG 1.5 server | yes | yes | **no** | yes | varies |

- 1.6 installs jq unconditionally: `working-1.6/lib/common/functions.sh:1981`, `packages="$packages jq"`.
- 1.5 never does; its own updater ships a private static `jq32` (`utils/FOGUpdater/fogupdater.sh:15`),
  which shows the gap is known upstream.
- FOS buildroot: `BR2_PACKAGE_BASH`, `BR2_PACKAGE_LIBCURL_CURL`, `BR2_PACKAGE_JQ`,
  `BR2_PACKAGE_OPENSSL` all set; `BR2_PACKAGE_PYTHON3` **not** set.

**Gate style to copy** — `_requestNodeCert()` at `working-1.6/lib/common/functions.sh:3455` is the
closest existing thing to an API client and the right template: `command -v` guards, `jq -e` for
presence checks, `// empty` for optional fields.

**Traps:**

- **Do not base64-encode the tokens.** The router does `base64_decode(HTTP_FOG_API_TOKEN)`, which
  reads as though the client must encode — it must not. The token the FOG UI issues is *already*
  base64 and `Invoke-FogApi` sends it verbatim. Re-encoding would double-encode and 401 every call.
- **`jq` exits 0 on empty input**, so exit status alone is not a success test. FOG's own code works
  around this at `functions.sh:559-565` (checks `PIPESTATUS`, file size, *and* literal `null`).
- **Detect 1.5 by absence of the `nextUrl` key**, not by truthiness — a present-but-null `nextUrl`
  still means 1.6. In jq: `has("nextUrl")`.
- **Prefer `openssl base64 -A` over `base64 -w0`** anywhere encoding is needed — busybox base64 (FOS)
  has no `-w`. Precedent at `functions.sh:3479`.

**Bash-only nicety:** when running on a FOG server, source `${fogprogramdir:-/opt/fog}/.fogsettings`
for `$webroot`/`$httpproto`/`$ipaddress` to derive the base URL, as every shipped FOG script does.
Zero-config on the box itself — something the PowerShell module structurally cannot offer.

**Style model:** `working-1.6/bin/fog-plugin-uploads.sh` (`set -u`, heredoc `usage()`, `case`
dispatch), not `installfog.sh`'s heavier GNU `getopt`.

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
   - **The inventory pair: layer refactor and local fixes only. No rename, no behavior change.**

     > `POST inventory/new` does **not** create a duplicate row per call — it sets the host's
     > inventory. If it ever does duplicate, that is a new bug on the FOG side, not here. **This path
     > is hot:** PXE runs it at task time, so every imaging task exercises it. Do not touch the
     > create-vs-update behavior.

     Do in 0.3, and nothing more:
     - `Set-FogInventory`'s hand-built `POST inventory/new` becomes
       `New-FogObject -type object -coreObject inventory`. Wire-faithful, since `POST /{class}`,
       `/{class}/create` and `/{class}/new` all resolve to the same `create` route. This removes the
       last non-fixed-route direct `Invoke-FogApi` caller.
     - Four local defects, none touching server behavior: line 43 is dead code (recomputes
       `$jsonData` then discards it), line 42 hardcodes `-verbose`, lines 31-33 let `$_` clobber a
       bound `-hostObj` (guard on `$PSBoundParameters`), and it returns nothing.
     - Leave names, aliases and behavior alone.

     **Why the rename waits.** `Get-FogInventory` does two unrelated jobs behind one name, and the
     right fix is a three-way split in Phase 5.5, not a swap now:

     | Branch | Job | Nature | Becomes |
     |---|---|---|---|
     | `else`, ~8 CIM classes | collect hardware from **this machine** | OS-specific client tooling | `Get-FogLocalInventory` |
     | `-fromFog` / posix | read inventory **stored on the FOG host** | cross-platform API read | `Get-FogHostInventory` |
     | `Set-FogInventory` | write inventory to the FOG host | cross-platform API write | `Set-FogHostInventory` |

     Both accurate names already exist as aliases today
     (`[Alias('Get-FogHostInventory','Get-WinInventoryForFog')]`), which is the module signalling the
     split it wants. The local-collection half is worth keeping as a first-class thing rather than
     folding away - it is a useful failsafe for pulling a host's inventory from client-side tooling
     when the fog client is not doing it - and it belongs with the other OS-specific tooling
     (`Mount-FogEfi`, `Set-FogBootToPxe`). The `"Not yet implemented"` posix stub is what
     `Get-FogLocalInventory` finally fills in, reusing what FOS already does with `lshw -json` and
     `dmidecode`. Old names survive as aliases onto whichever function inherits their behavior.
   - Delete the dead commented-out `Invoke-FogApi` lines in `Get-FogHostAssociatedSnapins.ps1` and
     `Set-FogSnapins.ps1`
