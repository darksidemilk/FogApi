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
| `Get-` cmdlets | **0** | **273** |
| `Invoke-` | 225 | 53 |
| `inferred without finding action` | one per operation | **0** |
| exact case-sensitive matches with this module's 164 cmdlets | — | **151** |

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

## What is still not generated

**Dynamic, server-driven argument completion.** Neither AutoRest nor this
repo's own emitter produces it — the emitter has 0 completers across all 161
generated cmdlets, so it is not ahead here. AutoRest ships a
`PSArgumentCompleterAttribute`, but it builds a static list from spec enums,
and FOG declares only three non-boolean enums.

That is a runtime concern: `Register-ArgumentCompleter` in the module, written
once. The spec-side work that makes it writable *generically* rather than
per-parameter is `x-fog-references` on foreign-key columns, so a completer can
know that `-imageID` is completed from the `image` class. FOG already holds
that relationship in each model's `$databaseFieldClassRelationships`.

## Note on `DefaultCommandPrefix`

It cannot supply the `Fog` prefix for binary cmdlets — 0 of 164 prefixed across
four configurations, contrary to Microsoft's documentation. See
`docs/AutoRestEvaluation.md`. The prefix has to come from the generator, which
is what `prefix: Fog` above does.
