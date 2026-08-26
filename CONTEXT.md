# CONTEXT

The vocabulary this project uses. A glossary and nothing else — no plans, no
decisions, no implementation detail. Those live in `docs/` and `docs/plans/`.

One context, not a map: the domain is FOG's own object model, and it is the same
domain for every client generated from the shared spec. Two contexts would
duplicate every term to say the same thing in two languages.

## The document

**OpenAPI document** — FOG's own description of its API, served live from
`GET {webroot}/system/openapi` and built per request, so it describes the classes
*that* server exposes, plugin contributions included.

**Snapshot** — `spec/openapi/fog-1.6.json`, the same document produced from a
checkout by `spec/tools/dump-openapi.php` with no server and no database. Fires
no plugin hooks, so it describes stock FOG. Its origin is recorded in
`spec/openapi/PROVENANCE.json`; the two are regenerated together, because a
snapshot with a stale provenance record is worse than no snapshot.

**Operation** — one entry in the document, identified by an `operationId` of the
form `Group_Action` (`Host_Get`, `Host_List`). The underscore is not cosmetic:
every generator splits on it to find the verb, and a document without it
generates nothing usable.

**Reference** — an `x-fog-references` annotation on a foreign-key column, naming
the class and field it points at. What makes server-driven tab completion
possible without teaching the client FOG's schema. A reference that disappears
upstream removes a completer and nothing fails, so their count is worth
watching.

**Page** — what a list, search or active route returns: the counts, the link and
the rows. A named schema per row type (`HostPage`), not an anonymous wrapper.

## Generation

**Generated cmdlet** — one exported command in the built module.

**Generated source file** — one `.cs` file AutoRest emits. **These are not the
same count and the difference matters.** AutoRest writes one file per
parameter-set variant (`_Create`, `_CreateExpanded`, `_CreateViaIdentity`) and
the build collapses them into a single exported proxy. 944 source files are 473
cmdlets. Any figure quoted without saying which is being counted is ambiguous,
and has been misread before.

**Synthesized name** — a model name the generator invented because the schema it
describes was written inline and had none, e.g.
`Paths8Cd1AsHostGetResponses200ContentApplicationJsonSchema`. A user reads these
in `OutputType`, in help and in IntelliSense. The fix is always upstream: name
the schema and `$ref` it.

**Surface** — the set of exported cmdlets and their parameters, recorded in
`spec/generators/surface.txt`. Because the generated client is not committed,
this snapshot is the only place a rename or a dropped parameter becomes visible
in review.

**Inference warning** — `inferred without finding action` in the generator log,
emitted when the verb could not be read from the `operationId` and was guessed.
The count is the pass/fail gate for a generation run and must be zero.

## The module

**Helper** — hand-written PowerShell in `custom/`. Either *non-API* (it talks to
the local machine or to settings, never to FOG) or *workflow* (it composes
several API calls, or reconciles state).

**Escape hatch** — `Invoke-FogApi`, the only way to reach a route the shipped
document does not describe, such as a plugin installed after generation.
Hand-written, because no generator emits a raw-path cmdlet.

**Reconciliation** — a helper that computes the difference between what FOG has
and what the caller asked for, rather than issuing a fixed call. `Set-FogSnapins`
and `Repair-FogSnapinAssociations` are the examples. Reconciliation is one of the
three reasons a helper survives generation, alongside making more than one API
call and touching the local machine.

**Local identity** — answering "which FOG host is *this* machine". FOG has no
route for it, so it is derived from CIM, DMI, NIC addresses and the hostname.
Nothing about it can be generated.

## Retired terms

**L1** — *do not use.* It meant the generic `-type`/`-coreObject` wrappers
(`Get-FogObject` and friends). Those are being deleted, and the plan briefly
redefined the term to mean the generated client that replaces them. A word that
now names its own replacement traps every future reader. Say **generated
client** for `FogProjectApi.cs`, and name the old wrappers directly.
