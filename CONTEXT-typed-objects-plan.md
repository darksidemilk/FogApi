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

### Phase 2 — input classes (the point) — **NEXT**

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
$t = [FogTaskRequest]@{ taskTypeID = 1; taskName = 'deploy'; shutdown = $false }
Send-FogImage -hostName <name> -TaskRequest $t          # no hashtable, tab-completes
New-FogObject -type object -coreObject host -jsonData $t # object accepted, not a JSON string
New-FogObject -type object -coreObject host -jsonData '{"name":"x"}'  # string still works
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
