# Generating FogApi from FOG's document

An earlier evaluation on `spike/generator-comparison` concluded that the
standard OpenAPI generators could not produce a usable module from FOG's
document — no `Get-FogHost`, names like `ConvertTo-FogdivHost` and
`Move-FogsHost` — and that a hand-written emitter was the only option.

**That conclusion was wrong.** AutoRest generates Az PowerShell and the
Microsoft Graph SDK; output that bad was a signal about the inputs, not the
tool. Three things were wrong, all on our side.

---

## How to build it

From the repo root, either OS:

```powershell
./make.ps1                  # Windows
```
```bash
./make.sh                   # Linux, macOS
```

Needs PowerShell 7, .NET SDK 8 and Node (for `npx`). PHP too, but only to dump
a document from a checkout — no FOG server and no database, because
`dump-openapi.php` calls `OpenAPI::document()` directly and building the
document touches no data.

`make.sh` delegates to `make.ps1` rather than reimplementing anything.
AutoRest's `build-module.ps1` hard-requires PowerShell Core, so the logic has
to run under `pwsh` either way and a second copy in bash would only drift.

### Stages, and running one at a time

```
make.ps1 / make.sh              root dispatcher: -Client, -Target
FogApi-clients/
  pwsh/builders/
    make.ps1                    this client's orchestrator
    buildFunctions.psm1         one function per stage
  python/builders/              scaffolding; not yet buildable
```

`Document → Generate → Compile → Merge → Surface → Help → Test`, and any one
of them alone:

```powershell
./make.ps1 -Target Compile              # recompile what is already generated
./make.ps1 -Target Surface -CheckSurface # the CI gate
./make.ps1 -Live https://fog.example.com/fog
./make.ps1 -Client all                  # every buildable client
```
```bash
./make.sh --target Compile
./make.sh --check-surface
```

A client is buildable when it has `builders/make.ps1`, so `-Client all` skips
`python` by name rather than failing, and adding that client needs no change
to the root script.

Generation takes a few minutes; the compile stage builds ~940 cmdlets and
~1,250 models and takes several more.

### What it does not build

The hand-written module. That is a different module with a different toolchain
— PlatyPS docs from comment-based help, plus psm1 concatenation — and it stays
callable on its own via `FogApi-clients/pwsh/invoke-modulebuild.ps1` until its
helpers are ported into `src/custom/`. The orchestrator uses AutoRest's own
help generation instead.

`Merge` is a real stage with nothing to do yet: `src/custom/` holds only
AutoRest's placeholders. It fails loudly rather than silently skipping once
that directory has content, because two things must be settled first — the
`.gitignore` covering `src/` has to be narrowed, and `--clear-output-folder`
has to be shown to spare `custom/`.

### `build-module.ps1` exits 0 when compilation fails

It calls `Write-Error` and returns success. **Never trust its exit code** —
check for the artifact:

```powershell
Test-Path ./FogApi-clients/pwsh/src/FogApi.psd1   # the real pass/fail
```

This is not hypothetical. The first attempt ever made to build this module
failed with 333 compile errors and reported success, which is also why nobody
had noticed that generating and compiling are different gates. `Get-` counts
and warning counts say nothing about whether the C# builds.

The `Compile` stage (`Invoke-FogApiCompile` in
`FogApi-clients/pwsh/builders/buildFunctions.psm1`) checks the artifacts rather
than the exit code, and greps the log for `error CS`.

### Pointing it at a real server

**The base URL is compiled in, not configured.** It comes from
`servers[0].url` and is emitted at 989 call sites in `FogProjectApi.cs`.
There is no `-BaseUri`, no `-Endpoint` and no runtime override.

An offline dump has no HTTP request to read a host from, so it emits the
documented placeholder `https://fog.example.invalid/fog`. A **live** document
carries the real one, because `Route::webrootbase()` reads the request host:

```powershell
./make.ps1 -Live https://YOUR-SERVER/fog
```
```bash
./make.sh --live https://YOUR-SERVER/fog
```

Both openapi routes sit in the router's unauthenticated allowlist, so
discovery needs no tokens.

Generating from a live document also picks up whatever plugins that server has
installed — no plugin hooks fire in an offline dump. See "Confirmed against a
live server" below.

### It cannot authenticate yet

`Module.cs` builds an `HttpPipeline` with no credential step, and FOG wants
`fog-api-token` and `fog-user-token` on every request. The only injection
point AutoRest offers is `-HttpPipelinePrepend`, which takes a C#
`SendAsyncStep` delegate rather than a scriptblock.

So a freshly generated module **imports and can be inspected, but every call
returns 401**. Wiring this up is the job of the hand-written
`custom/Invoke-FogApi.cs` plus the settings bootstrap, which is not written
yet. Do not expect to talk to a server with generated cmdlets alone.

### Known limits, and why they are handled where they are

`autorest-readme.md` carries three directives with the reasoning inline:

| what | why |
|---|---|
| two `multipart/form-data` routes removed | AutoRest cannot generate compilable multipart code at all — a probe with one `file` property fails identically. Not fixable upstream. |
| `Join-FogGroupByName` split out | `PUT` and `POST /group/join` merged into one cmdlet whose `-Body` had two types, which `Export-ProxyCmdlet` refuses. |
| `New-FogTaskQueue` split out | Same, for `POST /task` vs `POST /task/{id}/task`. |

Anything the generated surface cannot describe is reachable through
`Invoke-FogApi`, which exists for exactly that.

---

## 1. FOG's operationIds broke the convention

Every generator splits `operationId` on an underscore: the half before is the
noun, the half after is looked up in a verb table. AutoRest's configuration
reference says it outright — *"the operationId-method is the identifier that
comes after the underscore"* — and openapi-generator splits the same way.

FOG emitted `indivHost`. One word, no separator, **567 times**. So the group
came out empty, the verb table never matched, and the generator fell back to
guessing a verb out of the middle of the string. It warned on every operation:

```
warning | Operation indiv/usertracking is inferred without finding action.
```

Nobody read the log. That warning count is the real pass/fail signal for a
generation run.

Fixed upstream in **FOGProject/fogproject#1373**: `Host_Get`, `Host_List`,
`Host_Create`. Route names and permissions are untouched — only the id derived
from them changed.

## 2. The generator was invoked bare

`prefix` and `subject-prefix` are first-class config. `class.js` composes the
noun as `prefix + subjectPrefix + subject` — the same knob that puts the `Az`
in `Get-AzVirtualMachine`. Neither was passed, and the missing `Fog` prefix was
then written up as a generator limitation.

## 3. `verb-mapping` was never supplied

A documented config block. FOG's vocabulary is thirteen words covering 528 of
567 operations, and AutoRest's built-in table already handles most of them. It
also contains `Name: Move`, which is exactly why `namesHost` became
`Move-FogsHost`.

## What it produces now

`autorest-readme.md` in this directory is the whole configuration: a prefix,
two verb mappings, one directive.

```powershell
npx -y autorest --powershell autorest-readme.md --output-folder=out
```

Against the fixed document:

| | before | after |
|---|---|---|
| `Get-` cmdlets | **0** | **278** |
| `Invoke-` | 225 | **2** |
| `inferred without finding action` | one per operation | **0** |
| exact case-sensitive matches with this module's 164 cmdlets | — | **151** |

Counted by generated cmdlet file, against 1.6.0-beta.4078. The rest of the
surface is `Update-` 197, `New-` 131, `Join-` 100, `Remove-` 98, `Find-` 66,
`Measure-` 52, `Stop-` 16 — all approved verbs, no residue.

### Reproduced, and what the numbers are not

Re-run independently against **1.6.0-beta.4105** with
`Invoke-FogApiGeneration.ps1`, which pins autorest core 3.10.9 and
`@autorest/powershell@4.0.758`. Every figure above came back identical:
`Get-` 278, `Update-` 197, `New-` 131, `Join-` 100, `Remove-` 98, `Find-` 66,
`Measure-` 52, `Stop-` 16, `Invoke-` 2, and **0** inference warnings. 2,569
files, 944 of them cmdlets.

**"Counted by generated cmdlet file" is load-bearing, and documents derived
from this one have dropped it.** AutoRest emits one file per parameter-set
variant — `New-FogHost` alone is `_Create` and `_CreateExpanded` — and
`build-module.ps1` collapses those into a single exported proxy. So:

| | files | exported cmdlets |
|---|---|---|
| whole surface | 944 | **473** |
| `Get-` | 278 | 172 |
| `Update-` | 197 | 50 |
| `New-` | 131 | 56 |

473 is what a user sees in `Get-Command -Module FogApi`. The same trap applies
to the models: the often-quoted "973 synthesized `Paths*` names" is 973 *files*,
four per model, and is **280 distinct names** — 158 request-body, 122 response,
of which 49 are `allOf` fragments rather than whole bodies.

Two claims that were made from the pre-fix spike output and do **not** hold
against the fixed document:

- **Request bodies expand.** `New-FogHost` takes 28 real body parameters —
  `-name` (mandatory, carrying FOG's own `isHostnameSafe` help text),
  `-imageID`, `-ADDomain`, `-ADOU`, `-archID`, `-productKey`, `-useAD` and 21
  more. The claim that inline bodies leave only `-AdditionalProperties` was
  measured on a document that predated #1373 and #1399.
- **No degenerate or colliding names.** The empty-noun `Export-` and `Join-`
  cmdlets, and the `Get-Host` / `Get-Module` / `Get-History` collisions with
  PowerShell built-ins, all came from running with no config. With `prefix: Fog`
  applied, **0 of 473** names lack the prefix and none collide.

The host family generates as exactly what the module ships:

```
Find-FogHost  Get-FogHost  Join-FogHost  Measure-FogHost
New-FogHost   Remove-FogHost  Update-FogHost
```

`Host_Get` and `Host_List` merge into one `Get-FogHost` with `Get`, `List` and
`GetViaIdentity` parameter sets — the `-id` versus list shape the module
already has.

### The 13 that do not match

Three are `Invoke-FogApi`, `Set-FogTransport` and `Reset-FogTransport`. Those
are transport, not API operations, and they are correctly **not** generated.

The other ten are word order: this module says `Get-ActiveFogTasks` and
`Start-FogHostTask`, the generator says `Get-FogTaskActive` and
`New-FogHostTask`. Directives can rename them, which is the honest finding that
survives from the original evaluation — **the naming judgement does not
disappear, it moves.** `spec/overlay/fog-api-overlay.json` would be
re-expressed in AutoRest's dialect rather than deleted.

The difference is scale. It was 567 operations of nonsense; it is now ten
preferences.

## The convention holds for classes nobody planned for

`architecture` became a lookup table upstream (#1375) *after* this convention
was written, and went through it with no intervention at all:

```
Architecture_Get   Architecture_List    Architecture_Create  Architecture_Update
Architecture_Delete  Architecture_Search  Architecture_Join  Architecture_Count
```

which AutoRest turned into a complete, idiomatic family:

```
Get-FogArchitecture      New-FogArchitecture       Update-FogArchitecture
Remove-FogArchitecture   Find-FogArchitecture      Join-FogArchitecture
Measure-FogArchitecture  Get-FogArchitectureId     Get-FogArchitectureName
```

That is the shape this module hand-writes per class, generated for free for a
class that did not exist when any of this was set up. It is the evidence that
the convention is durable rather than fitted to one snapshot.

## Confirmed against a live server, plugins included

#1373 is merged. `GET /fog/system/openapi` from fog-dev at 1.6.0-beta.4095:
**578 operations, all 578 carrying the underscore**, 59 schemas. All gates pass
on the live document — `Group_Action`, no duplicates, every `$ref` resolves,
tag equals group.

The half a checkout dump structurally cannot show is plugin classes: no plugin
hooks fire without a server. The LDAP plugin's five classes came through the
convention untouched, and the casing fix reached them too — these are classes
FOG core knows nothing about:

| before | now |
|---|---|
| `Ldapgrouproleassociation` | `LDAPGroupRoleAssociation` |
| `Ldapgroupusergroupassociation` | `LDAPGroupUserGroupAssociation` |
| `Ldapusergrant` | `LDAPUserGrant` |

Generating from that document produced **45 fully formed cmdlets for a plugin
this module has never supported**, with no configuration written for it:

```
Get-FogLdapGroup    New-FogLdapGroup     Update-FogLdapGroup
Remove-FogLdapGroup Find-FogLdapGroup    Join-FogLdapGroup
Measure-FogLdapGroup  Get-FogLdapGroupId  Get-FogLdapGroupName
```

518 cmdlets total, 0 warnings, and the same 151 of 164 exact matches against
the module's own surface. That is the case `Get-FogApiSpec` was meant to
address — a plugin's classes appearing in *that user's* document — reached
through generation instead.

## openapi-generator, accurately

Its PowerShell output is **script modules, not binary cmdlets** — one
`.ps1` per API class holding every operation for it. `FogHostApi.ps1` is 1462
lines and 13 functions. The fix helped it too: grouping is now correct
(`FogHostApi.ps1`, `FogArchitectureApi.ps1`) and the operationId-derived
nonsense is gone.

Every operation is present, including the reads. They are named
`Invoke-{Api}{Operation}` — `Invoke-FogHostGet`, `Invoke-FogHostList` — so the
capability is complete and it is the verb *position* that differs, not the
coverage. Renaming to `Get-FogHost`, or splitting the module-style files into
one function per file, is mechanical work.

`commonVerbs` (`Delete=Remove:Patch=Update`) looks like the lever for that and
is not: passing it changes nothing here, because the generator composes
`Invoke-` + api + operation rather than reading a verb off the operation name.
Getting idiomatic names out of it means custom mustache templates or a
post-processing pass.

One defect is its own and worth recording, because it is not something the
document can fix — it strips verb-like prefixes without respecting word
boundaries:

| operationId | emitted |
|---|---|
| `Inventory_Get` | `ConvertTo-Fog`**`ventory`**`Get` |
| `Initrd_List` | `ConvertTo-Fog`**`itrd`**`List` |
| `Groupassociation_Get` | `Group-FogAssociationGet` |

`Inventory` is a legitimate noun.

## What is still not generated

**Dynamic, server-driven argument completion.** Neither AutoRest nor this
repo's own emitter produces it — the emitter has 0 completers across all 161
generated cmdlets, so it is not ahead here. AutoRest ships a
`PSArgumentCompleterAttribute`, but it builds a static list from spec enums,
and FOG declares only three non-boolean enums.

That is a runtime concern: `Register-ArgumentCompleter` in the module, written
once. What makes it writable *generically* rather than per-parameter is
`x-fog-references`, merged upstream in **FOGProject/fogproject#1382** and
derived from each model's `$databaseFieldClassRelationships`:

```json
"osID": {
    "type": "integer",
    "x-fog-references": { "class": "os", "field": "id" }
}
```

30 columns carry it, and one of them — `LDAPGroup.serverID -> ldap` — is on a
plugin class, read from the plugin's own relationship map.

The completer that needs is short, and knows nothing about FOG's schema:

```powershell
function Get-FogReferenceValue {
    param([string]$Schema, [string]$Property)
    $ref = $doc.components.schemas.$Schema.properties.$Property.'x-fog-references'
    if (-not $ref) { return @() }
    @((Invoke-FogApi -uriPath $ref.class).data) | ForEach-Object {
        [pscustomobject]@{ Value = $_.($ref.field); Label = $_.name }
    }
}
```

Run against a live server it completes every foreign key without being told
about any of them:

```
-imageID on Host  ->  GET /image, key 'id'      12 Base-Stable, 11 Test
-osID on Image    ->  GET /os, key 'id'          8 Apple Mac OS, 50 Linux, ...
-stateID on Task  ->  GET /taskstate, key 'id'   2 Checked In, 4 Complete, ...
```

That is the piece neither generator produces and the emitter never had — but
it is now fifteen lines rather than a hand-kept table of which column points
where.

## Note on `DefaultCommandPrefix`

It cannot supply the `Fog` prefix for binary cmdlets — 0 of 164 prefixed across
four configurations, contrary to Microsoft's documentation. See
`docs/AutoRestEvaluation.md`. The prefix has to come from the generator, which
is what `prefix: Fog` above does.
