# AutoRest.PowerShell, evaluated against FOG's document

Run on 2026-08-24 against `spec/openapi/fog-1.6.json` (FOG 1.6.0-beta.4013).

**Conclusion: AutoRest.PowerShell is the right long-term generator for this
module, and it is blocked on one upstream defect in FOG's OpenAPI document.**
Not on anything about AutoRest, and not on anything about FogApi.

## Reproducing this

```powershell
npx -y autorest --powershell `
    --input-file=spec/openapi/fog-1.6.json `
    --output-folder=out `
    --clear-output-folder
```

Versions the run resolved, from `~/.autorest`:

| package | version |
|---|---|
| `@autorest/powershell` | **4.0.758** (published 2026-08-13) |
| `@autorest/core` | 3.10.9 |
| `@autorest/modelerfour` | 4.26.2 |

That is the current v4 generator, not the v3 line. 162 seconds, 2,932 files.

## It is not deprecated, and an earlier claim in this repo was wrong

An earlier version of this evaluation said no supported standard existed for
generating C# PowerShell cmdlets from OpenAPI. That was wrong, and the mistake
is worth recording so nobody repeats it.

AutoRest's [deprecation notice](https://github.com/Azure/autorest/issues/5175)
retires the project on 2026-07-01 and names exactly five affected generators:
**C#, Java, JS/TS, Python, Go.** PowerShell is not among them and the issue does
not mention it. Reading the core notice and generalising it to the PowerShell
generator is the error.

The PowerShell generator ships from a separate npm package,
[`@autorest/powershell`](https://www.npmjs.com/package/@autorest/powershell),
and is actively developed: 4.0.752 in January 2026, 4.0.754 in March, 4.0.757
and 4.0.758 in August.

It is also what Microsoft's own generated modules use today. From the Az
PowerShell docs, dated 2026-08-04 for Az 16.2.0:

> We're moving forward with using the new version of the code generation tool,
> AutoRest.PowerShell v4, to take advantage of the features offered by the
> latest version. The redesign of the generated code to support new user
> requirements in this version inevitably introduces some breaking changes.

And from the [Microsoft Graph PowerShell SDK generation
process](https://github.com/microsoftgraph/msgraph-sdk-powershell/wiki/Generation-Process):

> Each module specific OpenAPI document is run through AutoREST.PowerShell to
> generate a PowerShell binary module containing models and cmdlets.

## What it does well

A complete module scaffold, not just cmdlets: `build-module.ps1`,
`generate-help.ps1`, `pack-module.ps1`, `test-module.ps1`, `export-surface.ps1`,
`create-model-cmdlets.ps1`.

`generate-help.ps1` matters most. Help for compiled cmdlets is the one piece
FogApi's own emitter does not yet produce, and AutoRest solves it as part of the
standard pipeline.

It also targets `netstandard2.0` with `PowerShellStandard.Library`, so its
cmdlets load on Windows PowerShell 5.1 as well as 7 — which would undo the 5.1
drop that is currently the only breaking change in the C# rewrite.

## The blocker: every computed field is dropped

FOG's `OpenAPI::_entitySchema()` reflects a model's own `$databaseFields` — its
columns — while the route returns that entity JOINED to its relations. `host`
declares 33 fields and answers with more. 80 such fields across 24 classes.

The document names them, but only in English, in the schema description. So
AutoRest copies that sentence into a doc comment and then generates a
deserialiser that reads none of them. From the generated
`out/generated/api/Models/Host.json.cs`:

```csharp
/// <summary>
/// Responses may carry computed fields that are not columns and are not settable through the generic create/edit path: mac,
/// primac, imagename, groups, hostscreen, hostalo, optimalStorageNode, printers, snapins, modules, inventory, task, snapinjob,
/// users, fingerprint, powermanagementtasks.
/// </summary>
```

The generated code documents the fields it discards. Measured:

- `Host.json.cs` reads exactly **33** properties, its declared columns.
- **0** of the generated models carry `additionalProperties` or
  `IAssociativeArray` support.
- `Printer.json.cs` reads its 13 declared properties and nothing else, so
  `hosts` is lost.

This is the same failure Kiota has, for the same reason: its `AdditionalData`
is an `IDictionary<string,object>`, which was separately measured **not** to
satisfy PowerShell member access — `$h.macs` returns `$null` through one.

## The fix is upstream, and it is small

If `_entitySchema()` emitted the computed fields as `readOnly` properties — the
names are already in `$vars['additionalFields']`, which is where the prose
sentence is built from — or set `additionalProperties`, AutoRest would generate
support for them and the blocker disappears.

That change was already on the list as "would help every generated client." It
is better understood as **the single thing standing between FOG and being
generatable by the industry-standard toolchain**, and it applies to anyone
generating a client from FOG's document, not only to this module.

## The other gap: naming

AutoRest derives cmdlet names from `operationId`, and FOG's operationIds are the
router's internal names. The generated surface for one class:

```
Invoke-IndivPrinter   Invoke-NamePrinter   Invoke-IdPrinter   Invoke-CountPrinter
Get-Printer   Set-Printer   New-Printer   Remove-Printer   Search-Printer   Join-Printer
```

No `Fog` prefix, `Set-` where this module uses `Update-`, and `Printerassociation`
rather than `PrinterAssociation`. It also emits **924 cmdlet files** against the
161 FogApi's emitter produces, because it generates a variant per parameter set
(`_Create`, `_CreateExpanded`, `_UpdateViaIdentity`, `_UpdateViaIdentityExpanded`).
That is the Az house style.

AutoRest has a directives mechanism for renaming, so this is solvable. But
directives are `spec/overlay/fog-api-overlay.json` re-expressed in AutoRest's
dialect — the judgement does not disappear, it moves. That is worth knowing
before treating "use the standard generator" as work avoided.

## Where this leaves the decision

1. Fix `_entitySchema()` upstream so computed fields are in the schema rather
   than in a sentence.
2. Re-snapshot.
3. Re-run the command at the top of this file.
4. If the computed fields survive, port the overlay's naming decisions to
   AutoRest directives and retire `spec/tools/New-FogCmdletSource.ps1`.

Until step 1 lands, a generated client cannot see 80 fields the server actually
returns, and that is not a trade this module can make — `Get-FogHost` would stop
returning `macs`.

## The manifest cannot supply the `Fog` prefix

Worth recording because it is the obvious idea, it is a real PowerShell
feature, and the documentation says it works.

`DefaultCommandPrefix` in a module manifest inserts a prefix into the **noun**
of every exported command, so `Get-Host` is imported as `Get-FogHost`. If that
applied here, AutoRest's missing `Fog` prefix would cost nothing to fix — no
directives, no overlay, one manifest key — and the `Get-Host` collision with
the PowerShell built-in would go with it.

`about_Module_Manifests` states it plainly:

> any cmdlets imported from this module have `Example` prepended to the noun
> in their name. For example, `Get-Item` is imported as `Get-ExampleItem`.

**It does not apply to binary cmdlets.** Measured on pwsh 7.6.4 against
`FogApi.Core.dll`'s 164 cmdlets, four ways:

| how the prefix was applied | functions | binary cmdlets |
|---|---|---|
| `DefaultCommandPrefix`, DLL in `RequiredAssemblies` + `NestedModules` | prefixed | **0 of 164** |
| `DefaultCommandPrefix`, DLL in `NestedModules` only | prefixed | **0 of 164** |
| `DefaultCommandPrefix`, DLL as `RootModule`, no `.psm1` | n/a | **0 of 164** |
| `Import-Module -Prefix Zz` | n/a | **0 of 164** |

A control in the same engine confirms the mechanism itself works: a script
module exporting `Get-Host2`, `Invoke-IndivHost` and `ConvertTo-divHost` with
`DefaultCommandPrefix = 'Fog'` exposes `Get-FogHost2`, `Invoke-FogIndivHost`
and `ConvertTo-FogdivHost`, and the unprefixed names stop resolving.

**Aliases are never prefixed either**, by either route. A module relying on the
prefix would have prefixed commands and unprefixed aliases pointing at them.

Three consequences:

1. **It does not rescue AutoRest.** Its `Get-Host` stays `Get-Host`. Renaming
   still has to happen in directives, which is the overlay re-expressed rather
   than deleted — the finding already recorded above.
2. **FogApi must not set it.** With 66 functions and 164 cmdlets, it would
   prefix the functions and leave the cmdlets alone, splitting the naming
   surface down the middle. The key is commented out in `FogApi.psd1` and
   should stay that way.
3. **It would work for openapi-generator**, whose output is entirely functions.
   That is not an argument for openapi-generator: its host surface is
   `ConvertTo-divHost` and `Move-sHost` before any prefix is applied, and
   prefixing mangled names yields prefixed mangled names.
