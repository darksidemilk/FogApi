# Why the whole of AutoRest's output is committed here

**AutoRest does not intend it to be.** The file now sitting beside this one as
`gitignore.as-emitted-by-autorest` is the `.gitignore` AutoRest wrote for this
project, verbatim. It excludes `generated/`, `internal/`, `exports/`, `tools/`
and every root-level `.ps1`/`.psd1`/`.psm1`/`.csproj`/`.nuspec` it produces —
that is, nearly everything AutoRest itself emits. What you are meant to commit
is the scaffold you hand-edit: `custom/`, `docs/`, `examples/`, `test/`, and
the autorest config. Everything else is regenerated on every build.

It is renamed rather than deleted so the stance survives as evidence, without
git acting on it.

That stance is a real architectural difference from this repo, and worth
noticing before adopting AutoRest: FogApi commits every generated `.cs` on
purpose, so a spec change shows up as a reviewable diff. AutoRest treats
generated code as build output. Those are two different answers to "where does
generated code live", not a detail.

The whole tree is committed here anyway because the point of this branch is to
let the three approaches be compared **for real** — read, diffed, and run —
without anyone first having to reproduce a 3,311-file generation. That is worth
the repository size on a spike branch.

To regenerate:

```powershell
npx -y autorest --powershell `
    --input-file=../fog-1.6-live-4020.json `
    --output-folder=. --clear-output-folder
```
