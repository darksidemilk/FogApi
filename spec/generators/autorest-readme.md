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

  # The two multipart/form-data routes are dropped because AutoRest cannot
  # generate compilable code for multipart at all. This is not FOG's
  # document being wrong, and it is not fixable upstream: a minimal probe
  # -- one object with a single `file` property, type string, format binary
  # -- fails identically with 6 CS0411 errors, `Extensions.AddIf<T>` and
  # `Enumerable.Select` unable to infer their type arguments. An array of
  # files fails the same way.
  #
  # Reach these two through Invoke-FogApi, which is hand-written precisely
  # so that a route the generated surface cannot describe is still
  # reachable. Delete this directive and regenerate if a later
  # @autorest/powershell learns multipart.
  - remove-operation: Snapin_CreateWithFile
  - remove-operation: Storagegroup_UploadSnapinFile

  # PUT /group/join and POST /group/join are different operations sharing a
  # route: the PUT applies one group's fields to a list of ids, the POST
  # resolves names and creates what is missing. Both parse as group "Group"
  # + action "Join", so AutoRest merges them into a single Join-FogGroup
  # with two variants -- and then Export-ProxyCmdlet refuses it, because
  # the merged -Body parameter has two different types:
  #
  #   The parameter 'Body' has multiple parameter types [...] which is not
  #   supported.
  #
  # Naming the two bodies upstream does not fix this. Two named types are
  # still two types on one parameter. They have to be two cmdlets, so the
  # POST is renamed to its own subject.
  - rename-operation:
      from: Group_JoinByName
      to: GroupByName_Join

  # Same class of collision, for the same reason. `task` is one of
  # Route::$validTaskingClasses, so POST /task/{id}/task exists alongside
  # POST /task. Their operationIds are Task_CreateTask and Task_Create;
  # AutoRest reads the verb off the front of the action and composes the
  # noun from the group plus what is left, so both land on New-FogTask once
  # the repeated "Task" is folded away.
  #
  # Export-ProxyCmdlet then refuses the merge, because three parameters end
  # up with two types each: -Body (ITask vs the queued-task body),
  # -Shutdown (IAny vs string) and -Wol (IAny vs int). The IAny pair comes
  # from the queued-task body declaring those fields as a oneOf.
  #
  # Renaming the group gives the queueing route a noun of its own and
  # leaves New-FogTask meaning what it says: create a task record.
  - rename-operation:
      from: Task_CreateTask
      to: TaskQueue_Create
```
