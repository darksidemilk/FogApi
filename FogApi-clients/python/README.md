# fogapi (Python) — planned

Nothing here yet. The directory exists so the shape of the repo is obvious
before the client is written, and so `FogApi-clients/` is visibly plural
rather than a folder with one thing in it.

## Why a second client at all

`spec/` is the shared truth: one snapshot of FOG's OpenAPI document, one
provenance record, one set of upstream fixes. Every client generates from it.
Each of the defects found while getting the PowerShell client to build was a
defect in the document, not in the generator, and every one of them would have
broken a Python client the same way — bare-array responses, anonymous request
bodies, `operationId`s with no verb separator.

That is the argument for the layout: the document is fixed once, upstream, and
every language benefits.

## Intended shape

Mirrors `pwsh/`:

```
python/
  build.ps1 (or a Makefile)   ours: version, invoke the generator, package
  resources/                  ours: anything shipped with the package
  src/                        the generator's scaffold, self-contained
```

Our tooling sits outside the generator's output, so regeneration never
overwrites something hand-written. `src/` is regenerated freely; anything we
maintain lives beside it, not inside it.

## Before starting

Read `spec/generators/README.md` first. It records which generator behaviours
are inputs-driven and which are hard limits — several cost real time to find,
and at least three will apply to any generator, not just AutoRest:

- a bare top-level array response cannot be modelled
- `multipart/form-data` may not be generatable at all
- the base URL is baked in from `servers[0].url`, so generating from a live
  server's document is how a client learns which server it talks to

Package name on PyPI is `fogapi`, per the naming decision: the module keeps its
name in every ecosystem, following that ecosystem's casing.
