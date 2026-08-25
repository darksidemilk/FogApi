# Three generators, same document

This branch exists to answer one question with artefacts rather than argument:
**what do the standard OpenAPI generators actually emit for FOG, and is either
of them a better basis for FogApi than the emitter in `spec/tools/`?**

Everything here is generated output, committed so it can be read and run. It is
a spike. Nothing in this directory is built, shipped, or imported by the module.

## What was run

All three read the same input: `fog-1.6.json`, the checked-in snapshot of
FOG's own document (1.6.0-beta.4013), produced by `spec/tools/dump-openapi.php`.

```powershell
# openapi-generator 7.25.0
npx -y @openapitools/openapi-generator-cli generate `
    -i fog-1.6.json -g powershell -o openapi-generator `
    --skip-validate-spec `
    --additional-properties=packageName=FogApi,apiNamePrefix=Fog

# AutoRest.PowerShell 4.0.758
npx -y autorest --powershell `
    --input-file=fog-1.6.json --output-folder=autorest --clear-output-folder
```

`--skip-validate-spec` is not a convenience. Without it openapi-generator
refuses outright — see "The document did not validate" below.

## The numbers

| | FogApi emitter | AutoRest.PowerShell | openapi-generator |
|---|---|---|---|
| Output | C# | C# | PowerShell |
| Files | 235 | 2,932 | 656 |
| On disk | 2.9 MB | 58 MB | 7.6 MB |
| Cmdlets | 161 | 924 | 517 |
| Models | 51 | 1,849 | 162 |
| Loads on PS 5.1 | no (net8.0) | yes (netstandard2.0) | yes |
| Generates help | not yet | yes (`generate-help.ps1`) | yes (`docs/`) |

AutoRest's 924 is not 924 commands — it emits a file per *parameter set*
(`_Create`, `_CreateExpanded`, `_UpdateViaIdentity`,
`_UpdateViaIdentityExpanded`). That is the Az house style.

## Naming

This is where the standard generators are weakest, because FOG's `operationId`s
are the router's internal names (`indivHost`, `namesPrinter`, `activeTask`) and
both generators derive cmdlet names from them mechanically.

**openapi-generator, all 517 names, by verb:**

```
225 Invoke      52 ConvertTo    51 Move    49 Join    48 Update
 48 New         31 Search        8 Stop     3 Set      1 Open   1 Export
```

**There is not one `Get-` cmdlet.** The most fundamental verb in PowerShell is
absent from the entire surface. Reads became `Invoke-`. And two families are
actively mangled — the generator strips what it thinks is a verb prefix out of
the middle of the operationId:

| operationId | emitted | should be |
|---|---|---|
| `indivPrinter` | `ConvertTo-FogdivPrinter` | `Get-FogPrinter` |
| `namesPrinter` | `Move-FogsPrinter` | `Get-FogPrinterName` |

`ConvertTo-Fogdiv` and `Move-Fogs` are not names anyone can guess, discover, or
defend. 52 and 51 of them respectively.

**AutoRest** is better but still raw: `Invoke-IndivPrinter`, `Invoke-NamePrinter`,
`Invoke-IdPrinter`, `Invoke-CountPrinter`, alongside a correct
`Get-Printer` / `Set-Printer` / `New-Printer` / `Remove-Printer`. No `Fog`
prefix, `Set-` where this module has always used `Update-`, and
`Printerassociation` rather than `PrinterAssociation`.

Both have a directives/overlay mechanism to fix this. That is the honest
finding: **the naming judgement does not disappear, it moves.**
`spec/overlay/fog-api-overlay.json` would be re-expressed in AutoRest's dialect
rather than deleted. Worth knowing before treating "use the standard generator"
as work avoided.

## The blocker both share: fields FOG returns but does not declare

`_entitySchema()` reflects a model's own columns; the route returns the entity
joined to its relations. `host` declares 33 fields and answers with 49. The
document names the other 16 — but only in English, in the schema description.

**80 such fields across 23 classes.**

Neither generator can read a sentence. Measured:

- **AutoRest** copies the sentence into a doc comment and then generates a
  deserialiser that reads none of the fields it names. `Host.json.cs` reads
  exactly its 33 declared columns. Zero generated models carry
  `additionalProperties` support.
- **openapi-generator is worse than lossy — it throws.** Its models validate
  every incoming key against a fixed list:

  ```powershell
  if (!($AllProperties.Contains($name))) {
      throw "Error! JSON key '$name' not found in the properties: ..."
  }
  ```

  Handed a real `printer` row, which carries the joined `hosts` relation:

  ```
  THREW: Error! JSON key 'hosts' not found in the properties: id name
  description port file model config configFile ip pAnon2 pAnon3 pAnon4 pAnon5
  ```

  So `GET /printer/1` fails outright against a stock generated client.

FogApi's own C# uses `System.Dynamic.DynamicObject.TryGetMember`, which was
measured to satisfy PowerShell member access — `$h.mac` resolves. (Kiota's
`AdditionalData` is an `IDictionary<string,object>`, which was separately
measured **not** to.)

### This is fixed upstream

**FOGProject/fogproject#1353** does two things about it. It emits those fields
as `readOnly` properties, and it states `additionalProperties` on the entity
schemas.

The second half matters as much as the first. Declaring the computed fields
fixes the 80 the document can *enumerate*; it cannot enumerate what a plugin
contributes at runtime, or what a later FOG adds after a client was generated
from a pinned snapshot. `additionalProperties` is what makes a generated
client tolerate those. It loosens nothing — the keyword already defaults to
true, so no validator's verdict changes — but most generators emit a catch-all
bag *only* when it is explicitly present.

Regenerating from that branch and re-running both generators, **with
validation enabled**:

- openapi-generator's `Host` model goes 33 → 49 properties, including `mac`,
  `imagename`, `inventory`, `snapins`, `groups`.
- Its `Printer` model accepts a real response carrying `hosts`, **and** one
  carrying a plugin-contributed field the document cannot know about. The
  throw-on-unknown-key path is gone from the generated model entirely.
- AutoRest's `Printer.json.cs` went from **no** `IAssociativeArray` at all to
  carrying one on both `FromJson` and `ToJson` — unknown keys now survive a
  round trip instead of being silently discarded.

Neither generator needed a directive, an override, or a patched spec.

#1353 is **merged** (`2c005465a`, on `working-1.6` since 1.6.0-beta.4020).

`fog-1.6-fixed.json` in this directory is that regenerated document, kept so
the before/after can be re-run without a fogproject checkout. It is
byte-identical to a fresh `dump-openapi.php` against merged upstream, apart
from `info.version`, which is a flag rather than something the code emits.

### Confirmed against a live server, which is where the plugin case shows up

`fog-1.6-live-4020.json` is `GET /fog/system/openapi` from a real 1.6.0-beta.4020
server. It is the more interesting artefact, because a checkout dump
structurally cannot produce it: **no plugin hooks fire when there is no
server**, so `dump-openapi.php` only ever describes the classes FOG ships with.

The live document carries **58 schemas and 407 paths** against the dump's 53 and
372. The extra five are the LDAP plugin — `Ldap`, `Ldapgroup`,
`Ldapgrouproleassociation`, `Ldapgroupusergroupassociation`, `Ldapusergrant` —
and 35 routes.

That is the case `additionalProperties` was argued for, and it holds:

- All five plugin schemas carry `additionalProperties`. 56 of 58 schemas do; the
  two that do not are `ListEnvelope` and `Error`, which are not entity schemas.
- `Ldapgroup` declares three computed fields — `roles`, `usergroups`,
  `ldapserver` — which before #1353 existed only in a prose sentence.
- Zero SQL-expression `default`s remain, and `Host` reads 49 properties with
  `mac` marked `readOnly`.
- openapi-generator generates from the live document **with validation
  enabled**, emits the five plugin models, and its `Ldapgroup` model parses a
  row carrying both the computed fields and a key it was never generated
  against — retaining the unknown value rather than throwing on it.

Checked separately, because declaring computed fields alongside columns could
have collided: **no schema has two properties differing only in case.**

## The document did not validate

openapi-generator refuses to generate at all:

```
SpecValidationException: There were issues with the specification.
Errors:
  -attribute components.schemas.Nodefailure.default=`current_timestamp()` is not of type `date-time`
  -attribute components.schemas.Snapintask.default=`current_timestamp()` is not of type `date-time`
```

`_columnSchema()` passed the MySQL `DEFAULT current_timestamp()` through as an
OpenAPI `default` on a `date-time` field. `default` must be an instance of its
own schema, so the document was invalid. AutoRest tolerated it silently;
openapi-generator did not. **Found only because this comparison was run** — and
also fixed in #1353.

## Where this leaves it

Nothing here is a reason to abandon the C# emitter today, and nothing here is a
reason to keep it forever.

- **openapi-generator is out** for this module: it emits PowerShell rather than
  C#, produces no `Get-` cmdlets, mangles two name families into nonsense, and
  its throw-on-unknown-key model is the opposite of what FOG's responses need.
  It earned its keep anyway — it found the validation defect.
- **AutoRest.PowerShell is the credible long-term option.** It is what Az and
  Microsoft Graph use, it is actively developed (4.0.758, August 2026), it
  targets `netstandard2.0` so it would undo the PS 5.1 drop, and
  `generate-help.ps1` solves the one thing FogApi's emitter does not yet do.
  See `docs/AutoRestEvaluation.md` for the full evaluation.
- **The gating question is no longer the blocker** — #1353 fixes it. It is
  whether porting the overlay's naming judgement into AutoRest directives buys
  more than it costs, against an emitter that already produces exactly the 161
  names this module has always shipped.

That is a decision to make after #1353 lands and the document can be
re-snapshotted, not before.
