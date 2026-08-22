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
| **1 — Spec + generator + coverage matrix + printer pilot** | **Done, awaiting review** | `claude/fogapi-openapi-spec-9o14r0` |
| 2-5 — Generate Tiers 1-3, hand-write fixed routes | Not started | one branch per tier |
| 6 — Test rebuild around language-neutral corpus | Not started | |
| 7 — Real-server CI + fog-workflows release gate | **Largely already exists** — see below | |
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

## Phase 1 — what shipped, and how the plan changed

**FOG 1.6 now describes itself.** `working-1.6` gained `lib/fog/openapi.class.php`,
which serves an OpenAPI 3.0.3 document at `GET {webroot}/system/openapi` with
`GET {webroot}/swagger.json` as an alias for the same handler. That is the single
biggest change to this plan since it was written, and it changes what Phase 1 *is*.

The original plan had `spec/fog-api-spec.json` hand-authored: someone reads the PHP,
transcribes every class, every field, every route shape, and keeps it current by
remembering to. That spec would have been wrong the first time a column changed and
would have had no way to know it. It is now **generated from FOG's own metadata**,
and the hand-written part shrinks to the part a server genuinely cannot know.

### The three-file pipeline

```
FOG checkout ──dump-openapi.php──> spec/openapi/fog-1.6.json   (generated, never edited)
                                              │
spec/overlay/fog-api-overlay.json ────────────┤  (hand-maintained, small)
                                              ▼
                              Build-FogApiSpec.ps1
                                              │
                                              ▼
                                  spec/fog-api-spec.json
                                              │
                    ┌─────────────────────────┼──────────────────────┐
                    ▼                         ▼                      ▼
      New-FogApiFunctionFile.ps1   Get-FogApiCoverage.ps1     Python / bash emitters
        (FogApi/Public/*.ps1)        (docs/ApiCoverage.md)          (phase 8)
```

The snapshot carries everything worth never retyping: 401 paths, 554 operations,
54 entity schemas, and per field the JSON type, the raw column name
(`x-fog-column`), `maxLength`, nullability, enum values, whether the server owns it
(`readOnly`) and whether it is required on create — plus `x-fog-permission` per
operation and `x-fog-paging` at the root. `Update-FogPrinter`'s
`[ValidateLength(0,250)]` on `-name` is not a number anyone typed; it is
`varchar(250)` on `printers.pAlias`, read through the document.

### The snapshot is generated offline, and verified against a live server

The document is built **per request** on purpose — `$validClasses` and the
sensitive-field lists are mutated at runtime by plugin hooks, so a build-time file
would omit every class a plugin adds. Right for a server, wrong for a code
generator: generating cmdlets has to be reproducible from a commit and reviewable
as a diff.

`spec/tools/dump-openapi.php` therefore calls `OpenAPI::document()` directly against
a checkout, rather than reimplementing it. That is possible because building the
document touches no data — the class lists are literal statics, the field maps come
from `ReflectionClass::getDefaultProperties()`, the types come from
`commons/schema-expected.php`, and defining a PHP class has no side effects. Four
things are stubbed and only four: `FOG_VERSION`, the request host, the hook manager,
and two `FOGBase` statics.

**Verified, not assumed.** A FOG 1.6 server was installed from the same commit
(`bin/installfog.sh`), the schema deployed, and `GET /system/openapi` diffed against
the checked-in snapshot key by key. **One difference, in `servers[0].url`**, which is
the deliberate placeholder. Recorded in `spec/openapi/PROVENANCE.json`.

### Corrections to the "Verified server facts" below

The hand-derived route list in that section was close but not exact. From the
document:

- **1.6 has ten generic per-class shapes, not eight.** `list`, `indiv`, `create`,
  `update`, `delete`, `search`, **`count`**, **`names`**, **`ids`**, **`join`** — all
  ten on all 52 classes bar `history`, which is read-only. Plus `task`/`cancel` on 8
  tasking classes and `active` (`{class}/current`) on 7.
- **`join` is `PUT /{class}/join`** and was not in the plan at all. The document
  described it as an upsert against the natural key; it is not, and that is covered
  under Phase 1.5 below.
- **`/search/{item}/{limit}` is not a second route.** It is an alias spelling of
  `/unisearch/{item}/{limit}`; the router registers `/[search|unisearch]/...` once.
- **`system/status` is not a separate route either** — `/system/[status|info]` is one
  registration with one handler and one payload, so the document describes
  `/system/info` alone.
- **`system/info` now carries `paging: {maxRows, expandMaxItems}`.** Phase 0's page
  sizing can read the server's real bounds instead of assuming; `x-fog-paging` at the
  document root says the same thing, and the API-validation workflow already asserts
  the two agree.
- **52 route classes, not "~50".** The document is the authoritative denominator, and
  `docs/ApiCoverage.md` is generated against it.

### Scope, now that the denominator is real

555 operations is not 555 cmdlets. Three shapes fold into parameters on another
cmdlet rather than becoming cmdlets of their own — `count`, `names` and `ids` onto the
list cmdlet, as `-Count`, `-NamesOnly` and `-IdsOnly`. That is 156 of the 555.

`join` was going to be a fourth, folded onto `New-Fog{Noun} -Upsert`. It is not: the
document's description of it was wrong, and the live server said so. See Phase 1.5. It
is now **deferred** — understood, deliberately unmodelled, with both semantics written
down in the overlay — and the coverage matrix has a distinct `d` state so a deferred
operation can never be miscounted as handled.

What the resolved spec says today:

| | count |
|---|---|
| Operations the server serves | 555 |
| Folded onto another cmdlet (`count`, `names`, `ids`) | 156 |
| Deferred, with the reason recorded (`join`) | 52 |
| Cmdlets specified for generation | 233 |
| Skipped because a hand-written function owns the name | 7 |
| Replacing an existing thin wrapper (old name kept as an alias) | 11 |
| Fixed routes, hand-written (tier 5) | 15 |
| Hand-written, registered rather than generated | 56 |
| Reachable only through L1, by choice | 86 |

The last row is the honest residual and is not a backlog. Nobody wants a typed cmdlet
for every write verb on every lookup table; the tiers are chosen against that number.

### The printer pilot, verified live

Six cmdlets emitted from the spec — `Get-FogPrinters`, `Get-FogPrinter`,
`New-FogPrinter`, `Update-FogPrinter`, `Remove-FogPrinter`, `Find-FogPrinter` — and
exercised against the live server, not only the mocks: create, list, get-by-id,
update, search, delete, the `id`-or-object pipeline contract, the `-settings` escape
hatch overriding a named parameter, and `[ValidateLength(250)]` rejecting 251
characters.

**Two emitter bugs the mocks would not have caught**, one of them sitting on top of a
real FogApi bug:

- **The `indiv` template appended `.data`**, copied from the `list` template where it
  belongs, so `Get-FogPrinter` returned `$null`. `Get-FogObject` is *correct* here and
  says so at `Get-FogObject.ps1:127`: a fetch by id returns the bare object because a
  single-object response has no envelope, and `Add-FogResultData` exists to normalise
  the 1.5-vs-1.6 **list** envelope specifically. Emitter fixed; nothing to change in
  the module. Worth writing down because the asymmetry is easy to re-introduce — every
  other template does take `.data`.
- **The `search` template omitted `-type search`,** relying on that parameter's
  default. A `DynamicParam` block sees only *bound* parameters, so with `-type` omitted
  `Set-DynamicParams` is handed `$null`, adds no `-coreObject`, and the call cannot
  bind. Passing it explicitly fixes the emitted code — but the fragility underneath is
  a genuine pre-existing FogApi bug: `Find-FogObject -coreObject host -stringToSearch x`
  has never worked, and nothing in the signature explains why, because `-type` looks
  optional and is. Belongs in Phase 0.5 with the rest of the dynamic-param work.

### Phase 1.5 — what the live server then found

Everything above was verified against mocks *and* a FOG 1.6 server built from
`working-1.6`. Running the real-server suite against it, rather than only the fixtures,
found four things the mocks structurally could not.

**`Find-FogObject -coreObject` never bound without an explicit `-type`.** Fixed: both
`Find-FogObject` and `Update-FogObject` declare a `ValidateSet` of exactly one value, so
their `DynamicParam` blocks now pass that literal instead of `$type`. `Get`/`New`/
`Remove-FogObject` take a genuine multi-value `-type` and still require it — asserted in
`Tests/DynamicParam.Tests.ps1` so the difference is deliberate rather than drift.

**`Invoke-FogApi` was discarding the server's explanation.** Its `catch` retried every
failure through `Invoke-WebRequest`, which got the identical refusal — so the caller saw
the *second* exception, whose message is a bare status line. A failing `New-FogHost`
reported `Response status code does not indicate success: 406 (Not Acceptable)` when the
server had said `Invalid hostname; must be 1-15 of these characters`. The retry also
doubled every failing request. It now surfaces the body (`ErrorDetails.Message`) and falls
back only for non-HTTP failures, which is what the fallback was for: FOG answers some
successful writes with an empty body that `Invoke-RestMethod` cannot parse.

**`join` is not what the document said.** It was folded onto `New-Fog{Noun} -Upsert` on
the strength of the summary *"upserts against the natural key"*. Against a real server,
PUT `/{class}/join` turned out to be a **bulk edit** over an explicit `ids` array — a body
without ids answers 202 and changes nothing — and the real upsert-by-name is the **POST**
variant, which is **group-only** (every other class answers 400) and was undocumented
entirely. Corrected upstream in `openapi.class.php`.

**The document overstated `host.name`.** `hostName` is `varchar(16)`, but
`Host::isHostnameSafe()` enforces 15 characters and a restricted charset. That is a model
rule, not a column property, so nothing derived from `schema-expected.php` could know it.
Added upstream via a small hand-kept `_applyModelConstraint()` map, verified against the
running server across eight names. The emitter turns `pattern` into `[ValidatePattern()]`,
so a generated cmdlet refuses a bad hostname at bind time rather than sending it and
getting a 406 that names no field.

The real-server suite itself was generating 22-character hostnames, so every Context that
created a host had been failing in its `BeforeAll` — which Pester reports as a spurious
*"'break' or 'continue' statement … escaped from your code"*, pointing nowhere near the
cause. Worth knowing before chasing one. Names are capped at 15 now.

**Also landed here:** `Get-FogObject -subPath` (`count`/`names`/`ids`) — the L1 addition
the folded switches needed. `Get-Fog{Noun}s -Count/-NamesOnly/-IdsOnly` are real, as
parameter sets so the binder rejects combining them, and all three return exactly what the
server sent because none carries a list envelope. The emitter gained `-Route` for
incremental work.

**Both these upstream fixes argue the same thing:** the document is worth treating as the
source of truth precisely *because* it can be wrong in a way a hand-written client cannot
notice. A wrong description that a generator consumes produces a wrong client silently. The
answer is to fix the description, not to work around it downstream — which is what
`fogproject` commits `31932e73e` and `a1e12d49b` do.

Suite: **111 mocked** (0 failing) and **128 against the live server** (0 failing).

### Phase 1 also closed four listed traps

- **Stale source manifest.** New `./update-sourcemanifest.ps1` rewrites the source
  `FunctionsToExport`/`AliasesToExport` from the files on disk, with `-Check` for CI.
  It found the root cause of the `Get-PendingMacsForHost` bug Phase 0 patched by
  hand: `Get-FogHostPendingMacs.ps1` had its `[Alias()]` *above* `[CmdletBinding()]`,
  and the build's reader only looks at the line immediately below. Attributes
  swapped; the script now warns whenever an alias sits anywhere the build cannot see
  it.
- **The 46-name inclusion list** in `Tests/FogApi.Examples.Tests.ps1` is inverted to
  manifest-driven-minus-exclusions, so a new cmdlet is covered the moment it exists
  and skipping one is a line a reviewer sees.
- **`Get-FogMockResponse` is now convention-based.** The hand-maintained
  `switch -regex` still wins, but unmatched paths fall through to shape matching
  (`GET {class}` → `{class}s.json`, `GET {class}/{id}` → `{class}.json`, and so on).
  A class opts in by having a fixture file; there is nothing to register. Four
  hand-written arms times 52 classes was never going to stay correct. The error
  message for a genuine miss now names the fixture to add.
- **The one-help-block rule bit the emitter itself** while it was being written: a
  literal close-comment marker inside its own `.DESCRIPTION` ended the block early
  and the prose after it parsed as code. Worth knowing before writing a generator
  that emits help blocks.

### New: the spec at runtime

`GET /system/openapi` is unauthenticated, which makes it usable for discovery before
credentials exist. Two things follow, both now specified in tier 5 rather than
speculative:

- **`Get-FogApiSpec`** fetches and caches the live document. That is the real fix for
  [#33](https://github.com/darksidemilk/FogApi/issues/33) (plugin API objects): a
  plugin's classes appear in the live document, so a spec-driven `ValidateSet` covers
  them without a FogApi release. Hardcoding them never can.
- **`Get-FogSystemInfo`** reads `system/info`, which now carries the version *and*
  the paging bounds in one cheap unauthenticated call. That is the shape Phase 0.5
  wants for killing the three-round-trip version probe.

### Phase 7 is further along than this doc thought

`FOGProject/fog-workflows` already has `.github/workflows/reusable_api_validation.yml`,
which installs FOG in distrobox, seeds API credentials, asserts the OpenAPI document
is served on both paths and is the same document, checks `system/info` and
`x-fog-paging` agree, then sets up FogApi and runs its real-server suite. It is not
blocked on the org move.

What it does not yet do is compare the live document against FogApi's checked-in
snapshot. That is the natural addition and the thing that would catch upstream adding
a class or changing a column before it reaches a release: fetch `/system/openapi`,
diff against `spec/openapi/fog-1.6.json`, and fail with the delta.

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

- **Stale source manifest.** ~~`invoke-modulebuild.ps1` updates only the `_module_build` copy of
  `FogApi.psd1`, never the source.~~ **Closed in Phase 1** by `./update-sourcemanifest.ps1`.
  Originally: `invoke-modulebuild.ps1` updates only the `_module_build` copy of
  `FogApi.psd1`, never the source. New functions are invisible to the test suite until the source
  `FunctionsToExport` is rewritten. This already bit once (`Get-PendingMacsForHost`, fixed in Phase 0).
- **`FogApi.psm1:4` globs `Public/*.ps1` non-recursively** — a `Generated/` subfolder would be
  silently skipped at import. Generated files therefore go flat in `Public/`.
- **One `<#...#>` block per file, help block first.** Both build scripts strip comments via
  `IndexOf('<#')`/`IndexOf('#>')` — first occurrence only.
- **`[Alias()]` must be on the line immediately after `[CmdletBinding(...)]`** — `Get-AliasesToExport`
  indexes that exact line and silently drops aliases declared elsewhere. Still true;
  `./update-sourcemanifest.ps1` now warns when it finds one the build would miss, and
  fixed the one live instance (`Get-FogHostPendingMacs`).
- **Closed in Phase 1.** ~~`Tests/FogApi.Examples.Tests.ps1` uses a hardcoded 46-name inclusion list~~ — new functions get
  zero tests, silently. Invert to manifest-driven-minus-exclusions (Phase 1).
- **Closed in Phase 1.** ~~`Get-FogMockResponse` throws on unmapped paths~~ and is a hand-maintained `switch -regex`.
  Phase 0 taught it to strip query strings; Phase 1 should make lookup convention-based.
- **`invoke-modulebuild.ps1:75` references `$docsPth`**, never defined, so the built module ships
  with no help content. Non-terminating, so CI passes today.

---

## Next session, start here

Phase 1 is on `claude/fogapi-openapi-spec-9o14r0`, branched from
`fix/fog16-paging-truncation` (Phase 0) because it revises this document. Merge order
is #62 → #63 → #64 → Phase 1.

Highest-value next steps, in order:

1. **Phase 0.3 / 0.5 first, not Phase 2.** Two things the pilot proved are needed
   before emitting 233 cmdlets:
   - The folded `-Count` / `-NamesOnly` / `-IdsOnly` switches have nowhere to go:
     `Get-FogObject` cannot address `{class}/count`, `{class}/names` or
     `{class}/ids`. It needs one `-subPath` parameter, or those switches stay
     unimplemented and 208 folded operations are folded into nothing.
   - `Find-FogObject`'s dynamic-param binding (above) is a live bug and every
     generated `Find-Fog*` works around it today.
2. **Wire the drift check into `reusable_api_validation.yml`** — diff the live
   document against `spec/openapi/fog-1.6.json`. Cheapest possible early warning for
   an upstream schema change, and the workflow already has a running server.
3. **Then Phase 2**, tier 1, `-Class host,group,image,snapin` and so on. The pipeline
   is proven; each tier is now mostly review rather than authorship.

Phase 0.3 scope (unchanged):
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
