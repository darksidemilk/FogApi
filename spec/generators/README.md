# Generating FogApi from FOG's document

An earlier evaluation on `spike/generator-comparison` concluded that the
standard OpenAPI generators could not produce a usable module from FOG's
document — no `Get-FogHost`, names like `ConvertTo-FogdivHost` and
`Move-FogsHost` — and that a hand-written emitter was the only option.

**That conclusion was wrong.** AutoRest generates Az PowerShell and the
Microsoft Graph SDK; output that bad was a signal about the inputs, not the
tool. Three things were wrong, all on our side.

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
