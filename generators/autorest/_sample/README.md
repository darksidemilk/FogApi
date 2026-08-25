# A readable sample of AutoRest's output

**AutoRest does not intend its generated output to be committed.** The
`.gitignore` it writes for you, one directory up, ignores `generated/`,
`internal/`, `exports/`, `tools/` and every root-level `.ps1`/`.psm1`/`.csproj`
it produces. What you are meant to commit is the scaffold — `custom/`, `docs/`,
`examples/`, `test/`, the autorest config — and regenerate the rest on every
build.

That is a real architectural difference from this repo, which commits every
generated `.cs` on purpose so a spec change shows up as a reviewable diff. It
is worth noticing before adopting AutoRest, because it is a different answer to
"where does generated code live" rather than a detail.

So the full 58 MB / 2,932 files are not in git. This directory is a hand-copied
sample, checked in so the comparison in `../README.md` can be read without
regenerating: the `printer` family, which is the class FogApi's own emitter was
piloted on, plus the `Host` and `Printer` models.

- `cmdlets/` — 34 files. Note the parameter-set explosion: `_Create`,
  `_CreateExpanded`, `_UpdateViaIdentity`, `_UpdateViaIdentityExpanded`. This
  is why 161 operations become 924 files.
- `models/` — 20 files. `Printer.json.cs` is the one to read: it deserialises
  its 13 declared columns and nothing else, so the joined `hosts` relation is
  dropped on the floor. `Host.json.cs` does the same for 16 fields, having
  first copied the sentence that names them into a doc comment.

To regenerate everything:

```powershell
npx -y autorest --powershell `
    --input-file=../fog-1.6.json --output-folder=. --clear-output-folder
```
