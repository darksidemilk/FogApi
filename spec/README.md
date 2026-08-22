# `spec/` — the machine-readable half of FogApi

FogApi's cmdlets used to be written one at a time, because someone needed one.
That produced a rich `host` family and nothing at all for the other forty-odd
FOG object classes. This directory is how the rest gets written: from FOG's own
description of itself, rather than from someone reading PHP and transcribing
field names.

It also makes the planned Python and bash ports *emitters* rather than
reimplementations. There is one spec and one set of naming rules; each language
renders them its own way.

## What is here

```
spec/
├── openapi/
│   ├── fog-1.6.json       FOG's own OpenAPI document. Generated. Never edited.
│   └── PROVENANCE.json    Which commit it came from, and how it was verified.
├── overlay/
│   └── fog-api-overlay.json   FogApi's decisions. Hand-maintained. Small.
├── fog-api-spec.json      The two resolved together. Generated. What emitters read.
└── tools/
    ├── dump-openapi.php          Produces the snapshot from a fogproject checkout.
    ├── Build-FogApiSpec.ps1      snapshot + overlay -> fog-api-spec.json
    ├── New-FogApiFunctionFile.ps1   The PowerShell emitter.
    └── Get-FogApiCoverage.ps1    Writes docs/ApiCoverage.md.
```

The split between the two inputs is the whole design. The snapshot is
everything a server can tell us and we should never retype: every path, method,
field, SQL-derived type, string length, enum, required flag, and the permission
each operation needs. The overlay is everything a server cannot know: what
FogApi calls things, which operations earn a typed cmdlet, which functions are
hand-written and must stay that way, and where FOG 1.5 differs.

## Where the snapshot comes from

FOG 1.6 serves an OpenAPI 3.0.3 document at `GET {webroot}/system/openapi`, with
`GET {webroot}/swagger.json` as an alias for the same handler. Both are in the
router's unauthenticated allowlist, so a client can discover the API before it
has credentials.

It is built **per request**, on purpose: `Route::$validClasses` and the
sensitive-field lists are both mutated at runtime by plugin hooks, so a file
generated at build time would omit every class a plugin contributes. That is
right for a server and wrong for a code generator — generating cmdlets has to be
reproducible from a commit, reviewable as a diff, and possible on a machine with
no FOG server on it.

So the snapshot is produced by `tools/dump-openapi.php`, which calls
`OpenAPI::document()` directly against a checkout. It works because building the
document touches no data: the class lists are literal static arrays, the field
maps come from `ReflectionClass::getDefaultProperties()`, the column types come
from `commons/schema-expected.php`, and defining a PHP class has no side effects.

```bash
php spec/tools/dump-openapi.php \
    --web /path/to/fogproject/packages/web \
    --version 1.6.0-beta.3789 \
    --out spec/openapi/fog-1.6.json
```

Four things are stubbed, and only four: `FOG_VERSION`, the request host, the
hook manager, and two `FOGBase` statics. The document produced this way was
diffed key by key against a live FOG 1.6 server built from the same commit and
came back identical apart from `servers[0].url`, which is a deliberate
placeholder. See `openapi/PROVENANCE.json`.

**1.6 only.** The 1.5 line ships no `commons/schema-expected.php`, so nothing
describes its types. The 1.5 deltas are hand-recorded in the overlay's
`fifteen` block, which is the honest place for them.

## Regenerating

Order matters — each step reads the previous one's output.

```powershell
# 1. Only when tracking a newer fogproject commit.
php spec/tools/dump-openapi.php --web <fogproject>/packages/web --version <ver> `
    --out spec/openapi/fog-1.6.json
# ... and update spec/openapi/PROVENANCE.json in the same commit.

# 2. After changing either input.
./spec/tools/Build-FogApiSpec.ps1

# 3. Emit cmdlets. Omit -Class for everything the spec specifies.
./spec/tools/New-FogApiFunctionFile.ps1 -Class printer

# 4. Resync the manifest, then the coverage report.
./update-sourcemanifest.ps1
./spec/tools/Get-FogApiCoverage.ps1
```

`Tests/FogApiSpec.Tests.ps1` fails if you skip a step: it rebuilds the spec into
a temp directory and compares, re-emits the pilot cmdlets and compares, and
checks the manifest against the files on disk.

## Rules

- **`fog-api-spec.json` and `openapi/fog-1.6.json` are generated.** Editing
  either is a change that disappears on the next rebuild, silently. Change an
  input.
- **Generated cmdlets in `FogApi/Public/` are generated too.** The same applies,
  and the drift test will catch it.
- **The builder validates rather than warns.** Unapproved verb, name collision,
  a class in two tiers or none, an overlay entry naming a function that does not
  exist — each is a non-zero exit and no output file. A spec that builds but is
  wrong becomes two hundred wrong cmdlets, which is worth being strict about.
- **Files go flat in `Public/`.** `FogApi.psm1` globs `Public/*.ps1` without
  `-Recurse`, so a `Generated/` subfolder would be skipped at import with no
  error.
