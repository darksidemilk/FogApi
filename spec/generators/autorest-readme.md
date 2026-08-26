# FogApi

> see https://aka.ms/autorest

``` yaml
input-file: fog.json
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
