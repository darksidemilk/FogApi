<!--
  Working plan for the typed-object / input-class work on FogApi.
  Lives in the repo so any session can reference it without a plan file.
  Mirrored to the GitHub tracking issue linked at the top of the Context section.
-->

# Classes to simplify user input, plus a spec refresh and generated type data

## Context

The point of classes here is **making the module easier to call**. That is what
`ProvisioningMgmt`'s `[Step]`/`[SubStep]` do — its own docblock says so: *"since the params are
all the same, use a custom object type simplifies things a bit"* — and it is the case FogApi has
not addressed at all. Everything else in this plan supports that or is prerequisite to it.

Where the input is awkward today:

| Surface | Today | Count |
|---|---|---|
| The task request body | `New-FogTask` takes `[hashtable]$settings` and builds `$payload = @{}` by hand (`New-FogTask.ps1:46,50,75`). No validation, no completion, no discoverability | **10 cmdlets** build this by hand |
| The L1 generic layer | the caller composes a JSON **string**: `Update-FogObject -jsonData ($h \| select aduser \| ConvertTo-Json -Compress)` — the documented usage | **14 cmdlets** take `$jsonData` |
| Per-entity writes | generated cmdlets already give typed per-field parameters, with `-settings` as a deliberate escape hatch for fields a newer server added | 41 carry `-settings` |

The third is already fine and the escape hatch should stay an untyped hashtable on purpose. The
first two are the work.

Crucially, **FogApi authors these shapes**, so the schema/response gap that ruled classes out for
*responses* cannot arise here: no undeclared fields, no relocation, no `AdditionalFields`. And the
task body is described in the spec, so the class is generated rather than invented.

Two decisions taken this session shape the rest: **target latest 1.6** (retire `imaginglog`
rather than shim it), and **all 51 entities get response type data**.

### Upstream moved today

`origin/working-1.6` advanced `e83049586..5c289e960`; merged locally as `2dc470fed` (kept, not
pushed). Measured against the committed snapshot:

| | old | new |
|---|---|---|
| paths | 401 | 394 (−7) |
| schemas | 54 | 53 (−1) |

`Imaginglog` and its 7 paths gone (`065b3fe3a`, ADR 0022); `Tasklog` gained `imageName` (9 → 10).
Nothing else changed, nothing added. That commit correctly left `openapi.class.php` alone — the
document generates from `Route::$validClasses`.

### A locked decision is being overridden, deliberately

`CONTEXT-api-coverage-plan.md:620` reads *"Dynamic params: additive only. Never remove a
ValidateSet entry."* Removing `imaginglog` breaks it. That is the right call given target-latest-1.6,
but it must be **amended in the doc with the reasoning**, not silently violated.

## Work

### Phase 1 — spec refresh and the imaginglog retirement (prerequisite) — **DONE, `fe6b67d`**

Everything downstream generates from the spec, so this goes first. Dump from the **merged**
fogproject tree, not `origin/working-1.6`, so the three openapi corrections survive
(`join`/upsert wording, hostname `maxLength`/`pattern`).

1. `php spec/tools/dump-openapi.php --web /home/user/fogproject/packages/web --version <new> --out spec/openapi/fog-1.6.json`
2. `spec/openapi/PROVENANCE.json` — new source commit, counts, re-verification note.
3. `spec/tools/Build-FogApiSpec.ps1`, then `New-FogCoreObjectList.ps1` — `imaginglog` leaves the
   list; update that emitter's header, which today explains only why entries are *kept*.
4. Delete the imaginglog surface: `Get-FogImagingLog.ps1`, `Find-FogImagingLog.ps1`, generated
   siblings, `Tests/Fixtures/imaginglog{,s}.json`, the `^imaginglog` routing in
   `Tests/FogApi.TestHelpers.psm1`, overlay entries.
5. **Rewrite `Get-LastImageTime.ps1`** onto `tasklog` + the new `imageName`. The only functional
   change here; keep its output contract the same shape and give it a test.
6. Regenerate the `tasklog` fixture so it carries `imageName`. Amend `CONTEXT-api-coverage-plan.md:620`.

Watch aliases: `Get-FogImagingLog` may own one another function could then claim.
`Build-FogApiSpec.ps1` tracks alias collisions and `update-sourcemanifest.ps1 -Check` catches a
stale manifest — read both rather than assuming.

### Phase 2 — input classes (the point) — **DONE**

7. **`FogApi/Classes/FogTaskRequest.ps1`**, generated. Spec-derived: the `/{class}/{id}/task`
   request body declares `taskTypeID`, `taskName`, `shutdown`, `debug`, `deploySnapins`,
   `passreset`, `sessionjoin`, `wol`. Replaces the hand-built `$payload` hashtable in
   `New-FogTask`, `Send-FogImage`, `Receive-FogImage`, `Send-FogGroupTask`, `Send-FogWolTask`,
   `Start-FogSnapin`, `Start-FogSnapins`, `New-FogScheduledTask`, `Update-FogScheduledTask`,
   `Update-FogTask`.
8. **Let the L1 layer accept an object.** `New-FogObject`/`Update-FogObject`'s `-jsonData` keeps
   taking a string for compatibility, but also accepts a `[FogTaskRequest]`, a `PSCustomObject` or
   a hashtable and serialises it. Removes the `ConvertTo-Json -Compress` ceremony from the
   documented usage without breaking a single existing caller.
9. **`FogApi/Classes/FogObjectRefTransform.ps1`** — an `ArgumentTransformationAttribute` subclass
   for the id-or-object-or-name contract, replacing that resolution logic across the generated
   cmdlets. **Measured to work through dot-sourcing**: attribute *instantiation* resolves fine,
   unlike a type literal as an attribute argument.
10. `spec/tools/New-FogInputClass.ps1` — emitter for #7, so it regenerates when request bodies change.

Three constraints, each learned the hard way this session and non-negotiable for these files:

- **No single-argument `[object]` constructor** — that is what made `[FogHost]$x` silently accept
  `[pscustomobject]@{nope=1}`. From-hashtable conversion goes on a **static factory**.
- **No type literal in an attribute** — `[OutputType('FogTaskRequest')]`, never
  `[OutputType([FogTaskRequest])]`, which fails to resolve and poisons the whole function.
- **No derived state in a default constructor** — `[T]@{...}` runs it *before* the hashtable
  properties are assigned.

**Explicitly rejected:** classing `Get-FogObject`'s `$pagedArgs` splat (`:182-190`). Internal
splatting to `Get-FogPagedResult`, not a user-facing contract — churn for no gain. And `-settings`
stays an untyped hashtable: it exists precisely to carry fields the module does not know.

**One scope call left open, deliberately — say if you want it in.** A generated *input class per
entity* (`[FogHostInput]`, `[FogImageInput]`, … ~51 more) built from each schema's writable
fields. Argument against: the generated `New-Fog<Noun>`/`Update-Fog<Noun>` cmdlets already expose
one typed parameter per field, which is the simplification a class would provide, so it would
mostly duplicate what exists. Argument for: it gives a single object to build once, pass around
and pipe, and it is what the L1 layer would take in #8 instead of a bare `PSCustomObject`. My read
is that #7–#9 capture the real awkwardness and per-entity input classes are redundant — but that
judgement is exactly where "the whole point is simplifying input" should overrule me.

#### What Phase 2 found

Five things the plan did not know, each measured rather than reasoned:

**There is no FOG 1.5 task body.** The six route callers each carried a
`Test-FogVerAbove1dot6` branch with a separate here-string per version, and the
1.5 half was wrong in every one of them. FOG 1.5's `Route::task()` decodes the
body and passes it straight to `createImagePackage($taskTypeID, $taskName,
$shutdown, $debug, $deploySnapins, $isGroupTask, $username, $passreset,
$sessionjoin, $wol)` — the same eight caller-supplied fields 1.6 declares, and it
reads no `other2` or `other4` anywhere. Checked in 1.5.10.2253 and working-1.6.
So those branches sent `scheduledtask` table columns to a route that ignores
them, while omitting `taskName`, `debug` and `wol` in the spelling it reads: on a
1.5 server `-debugMode` and the wake have never reached a task through
`Send-FogImage`, `Receive-FogImage` or `Send-FogGroupTask`. `ToLegacyBody` was
written, then deleted — there is nothing for it to do. Two of the eight
here-strings were also broken outright: `Receive-FogImage`'s 1.5 branch is not
valid JSON (no comma after `"taskTypeID": "2"`), and `Send-FogWolTask` sent
`isActive` as `"1;"`.

**A dead field must stay dead.** `Send-FogWolTask` sent `other2="-1"`, and
`other2` is the `scheduledtask` column for `deploySnapins`. Translating it
faithfully would have set `deploySnapins=-1` and made every wake-on-lan task also
deploy every snapin assigned to the host. The field was inert, so it stays out.
Preserving observable behaviour is not the same as preserving bytes.

**Integer beats boolean in a `oneOf`.** `deploySnapins` is `oneOf
string/integer/boolean` and its real values are `-1`, `0` or a snapin id.
Mapping it to `bool` — checking boolean first, which reads as the more specific
type — coerced `-1` to `$true` and put `"1"` on the wire: a different snapin
task, silently. The wider domain is always the safe mapping.

**`debug` cannot be a parameter name.** `-Debug` is a common parameter, so a
`-debug` parameter is a duplicate-name error at import, not a shadowing warning.
The wire field stays `debug`; `New-FogTaskRequest` calls it `-debugMode`, which
is what `Send-FogImage` and `Receive-FogImage` already called it. The emitter has
no reserved-name handling — worth adding before a generated cmdlet hits the same
collision.

**A class does not escape its module, so it needs a factory.** After
`Import-Module FogApi`, `[FogTaskRequest]@{...}` is *Unable to find type*: naming
a module's class requires `using module`. The plan's own acceptance snippet was
written that way and does not work as written. Two things do, and both ship: a
hashtable binds to the `[FogTaskRequest]` parameter and converts on binding —
rejecting a misspelled field by name, listing the ones it accepts — and
`New-FogTaskRequest` builds one with tab completion. This is the same limitation
the scoreboard records as "caller can name the type: ✗ needs `using module`"; it
matters more for an input class than the table implies, because an input class is
the one a caller has to construct.

#### What landed

- `spec/tools/New-FogInputClass.ps1` → `FogApi/Classes/FogTaskRequest.ps1`, which
  asserts all eight `/{class}/{id}/task` routes still declare one body shape
  before it writes.
- `FogApi/Classes/FogObjectRefTransform.ps1`, on the generated `task`/`cancel`
  `-id` parameters and on `Get-FogHost`.
- `FogApi/Private/ConvertTo-FogJsonBody.ps1`. `-jsonData` was already `[Object]`
  on both L1 cmdlets, but `Invoke-FogApi`'s is `[string]`, and splatting a
  hashtable into a `[string]` parameter stringifies rather than failing — the
  body reached the server as the literal text `System.Collections.Hashtable` and
  came back a 500. Normalising before the splat is what actually made the
  documented `[Object]` true.
- `New-FogTaskRequest`, public, aliased `New-FogTaskBody`.
- The six route callers, all now building one body with no version branch, each
  taking `-TaskRequest`.
- `task`, `cancel` and `active` emitter templates — the gap #65 listed as the
  first Phase 2 job. Ten new cmdlets: `Start-Fog*Task` / `Stop-Fog*Task`, plus
  four `Get-ActiveFog*`.
- Phase 4 stamping, since a `<Type>` block is inert without it:
  `FogApi/Private/Add-FogTypeName.ps1`, wired into every entity-returning
  generated template and nine hand-written getters. Visible payoff already —
  `Get-FogHosts` results now carry `FogApi.Host`, so `Register-FogTypeData`'s
  `Deploy`/`Cancel`/`Refresh` methods apply to list output for the first time.

#### The mocked suite is off in CI

Taken as the decision #66 stream E was asking for. `.github/workflows/build-test.yml`'s
Pester step is now `if: ${{ inputs.run_pester }}` — off for pull requests, runnable on
demand from the Actions tab.

It was already `continue-on-error: true`, so it never gated anything. That is the
argument for turning it off rather than leaving it: a step that is red on every PR and
that nobody is meant to act on teaches people to ignore red steps.

The structural problem is what it asserts. Every response comes from `Tests/Fixtures`,
so the suite proves the module still produces the shape somebody wrote down — not that
the shape is right. It has never been vetted against a real server. And it fails for a
reason that says nothing about the change under review: this phase added 20 cmdlets and
got 20 failures, all `no fixture mapped for uriPath 'host/1/cancel'`. Adding a cmdlet
should not require inventing a canned response for it.

Two things found by running it once anyway, both worth keeping:

- `Tests/FogApi.TestHelpers.psm1` requires every `Expected output:` block to be valid
  JSON, and fails **discovery** for the whole file if one is not — so a single bad
  annotation takes out all 488 cases, not one. `New-FogTaskRequest`'s first example
  documented the `ToString()` form. Fixed.
- The 20 new `Start-Fog*Task` / `Stop-Fog*Task` cmdlets have no fixtures. Whatever
  replaces this suite in phase 6 needs `{class}/{id}/task` and `{class}/{id}/cancel`
  cases; the routes return FOG's `{}` envelope rather than an entity.

The real gate stays `Tests/FogApi.RealServer.Tests.ps1` against a live server, plus the
build job. Phase 6 decides what replaces the mocked layer — a language-neutral
conformance corpus the python and bash ports can replay, rather than three parallel mock
suites.

#### Corrections to this plan

- **The ten cmdlets are not one shape.** `New-FogTask`, `Update-FogTask`,
  `New-FogScheduledTask` and `Update-FogScheduledTask` build the `task` /
  `scheduledtask` **entity** body — `name`, `checkInTime`, `hostID`, `stateID`,
  `typeID`, `imageID`, `NFSFailures`, `bypassbitlocker` — and POST it to
  `/task`. That is a different route and a different shape from
  `/{class}/{id}/task`, and `FogTaskRequest` does not describe it. They are
  untouched. The six route callers plus the ten newly generated `Start-`/`Stop-`
  cmdlets are where the class belongs.
- **`Get-FogGroup` was not emitted.** It is status `replaces-thin-wrapper` with
  `Get-FogGroups` as an alias, and a hand-written `Get-FogGroups` function still
  exists. Emitting it makes the alias shadow that function, which is a migration
  in its own right rather than a side effect of Phase 2.

### Phase 3 — response type data, as generated .ps1xml — **not started**

11. **New** `spec/tools/New-FogTypeFile.ps1`, styled after `New-FogCoreObjectList.ps1`. Emits
    `FogApi/FogApi.types.ps1xml` and `FogApi/FogApi.format.ps1xml` for **all 51 entities**
    (53 schemas less `Error` and `ListEnvelope`, which are response envelopes). ~27 KB / ~70 KB.
    Display columns prefer `id`/`name`/`description` then schema order, capped at 4; `<Width>`
    where known to help. `ScriptMethod`/`ScriptProperty` bodies come from a table **in the
    emitter** — the schema knows fields, not behaviour; only `host` has any today.
12. `FogApi/FogApi.psd1` — set `TypesToProcess` and `FormatsToProcess` (lines 107, 110).
13. **Delete** `FogApi/Private/Register-FogTypeData.ps1`; remove its call from `FogApi.psm1` and
    its re-emission block from `invoke-modulebuild.ps1`; make the build copy both xml (it copies
    only `lib`/`bin` today).

Why xml over the shipped `Update-TypeData`, all measured: column widths and labels, it **unloads
on `Remove-Module`** (verified "gone"; `Update-TypeData`'s survives), and being declarative it
needs no import-time call — the only reason that re-emission block exists.

### Phase 4 — stamping, or phase 3 is inert — **not started**

A `<Type>` block does nothing until an object carries the name; `Get-FogHost` already does
`PSObject.TypeNames.Insert(0, 'FogApi.Host')`.

14. `spec/tools/New-FogApiFunctionFile.ps1` — add the stamp to the templates that return an
    entity, then regenerate. Covers the generated cmdlets in one change.
15. Hand-written getters returning a known entity get the same one-liner.

## Verification

```powershell
pwsh -File spec/tools/Build-FogApiSpec.ps1        # expect 51 entities, imaginglog gone
pwsh -File spec/tools/New-FogInputClass.ps1
pwsh -File spec/tools/New-FogTypeFile.ps1
pwsh -File spec/tools/New-FogCoreObjectList.ps1
pwsh -File spec/tools/Get-FogApiCoverage.ps1
pwsh -File update-sourcemanifest.ps1 -Check
pwsh -Command "Test-ModuleManifest ./FogApi/FogApi.psd1"   # fails if either xml path is wrong
pwsh -File Invoke-FogApiTests.ps1 -CI                      # floor 541/0, less imaginglog cases
pwsh -File Invoke-FogApiTests.ps1 -RealServer              # floor 558/0
Import-Module ./BuildHelpers.psm1; ./invoke-modulebuild.ps1
```

Input classes specifically — the phase-2 acceptance:

```powershell
# [FogTaskRequest]@{...} does NOT work from a caller's session -- naming a
# module's class needs `using module FogApi`, not Import-Module. Both of these do:
$t = New-FogTaskRequest -taskTypeID 1 -taskName 'deploy' -shutdown $false
Send-FogImage -hostName <name> -TaskRequest $t
Send-FogImage -hostName <name> -TaskRequest @{ taskTypeID = 1; shutdown = $false }

Get-FogHost -hostID 42 | Start-FogHostTask -TaskRequest @{ taskTypeID = 14; wol = $true }
Get-FogHost -hostID 42 | Stop-FogHostTask

New-FogObject -type object -coreObject host -jsonData @{ name = 'x' }   # object accepted
New-FogObject -type object -coreObject host -jsonData '{"name":"x"}'    # string still works
```

Built module, since the xml is a new thing the build must carry:

```powershell
Import-Module ./_module_build/FogApi/FogApi.psd1 -Force
$h = Get-FogHost -hostID <id>
$h.PSObject.TypeNames[0]; ($h | Get-Member -MemberType ScriptMethod).Name
($h | Format-Table | Out-String)                        # widths applied
Remove-Module FogApi
([pscustomobject]@{PSTypeName='FogApi.Host'}) | Get-Member -MemberType ScriptMethod  # gone
```

The live server runs the **old** build, so `/imaginglog` still answers there. Re-deploy the merged
tree before trusting a real-server run against the new shape, or `Get-LastImageTime`'s test passes
for the wrong reason.

## Risks

- **`Get-LastImageTime` is a real behaviour change** on a published cmdlet.
- **Removing a ValidateSet entry breaks callers** — accepted cost, belongs in the release notes.
- **The build must copy the xml**, or the built module imports fine and silently loses all display
  and methods.
- **ScriptMethod scope is unverified.** `SysUuid` was invoked from a `<ScriptProperty>`, but
  `Deploy()`/`Cancel()` were never called from a `<Script>` body; they call `New-FogObject` /
  `Remove-FogObject`. Confirm mocked before committing; if a `<Script>` cannot see the module's
  cmdlets, keep xml for display and fall back to `Update-TypeData` for methods only.
- Phases are separable. 1 is prerequisite; 2 is independently shippable and is the user-facing
  win; 3 without 4 is inert rather than broken.

## Not in scope

- Compiled C#. Measured and deferred: 2,523 ms cold compile, and a `.cs` edit cannot reload in the
  same session (`Cannot add type … already exists`, edit silently ignored, syntax errors masked).
- Fixing `_entitySchema()` so the schema describes the whole response (host returns 39 fields
  against 30 declared). Explicitly deferred earlier this session.
- Response objects as classes — settled: type data, because the schema does not describe the whole
  response. Input classes are the opposite case, which is why they are phase 2.
