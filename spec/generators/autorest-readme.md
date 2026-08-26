# FogApi

> see https://aka.ms/autorest

Run this with `Invoke-FogApiGeneration.ps1`, which pins the generator versions.
Invoking `autorest` directly against this file works, but pins nothing -- and the
generated surface is not committed, so an unpinned run is the one thing that can
change the shipped module without changing a tracked file.

``` yaml
# The committed snapshot, produced by spec/tools/dump-openapi.php and recorded
# in spec/openapi/PROVENANCE.json. Relative to this file.
#
# It must be a document whose operationIds carry the underscore that
# FOGProject/fogproject#1373 added -- every generator splits operationId on `_`
# to find the verb, and without it AutoRest falls into its guess-a-verb path and
# warns once per operation. Invoke-FogApiGeneration.ps1 asserts this before
# spending three minutes on a run that cannot succeed.
input-file: ../openapi/fog-1.6.json

module-name: FogApi
namespace: FogApi

# The `Fog` in Get-FogHost. class.js composes the noun as
# prefix + subjectPrefix + subject -- the same knob that puts the `Az` in
# Get-AzVirtualMachine. Without it this module exports Get-Host, which
# collides with the PowerShell built-in.
prefix: Fog

verb-mapping:
  # Not in the built-in table, so Host_Count would land in the
  # guess-a-verb path. It cannot map to Get: the subject would be Host and
  # it would collide with Host_Get. Measure is the approved verb for
  # "how many".
  Count: Measure

  # The module has always used Find-, and its docs and aliases say so.
  Search: Find

directive:
  # AutoRest rewrites Update to Set for a PUT, hardcoded after the verb
  # map (create-commands-v2: `wait! "update" should be "set" if it's a
  # PUT`), so verb-mapping cannot reach it. That is the Az house style;
  # this module uses Update-.
  - where:
      verb: Set
    set:
      verb: Update
```
