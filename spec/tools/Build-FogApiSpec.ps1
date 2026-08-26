#Requires -Version 5.1
<#
.SYNOPSIS
Resolves spec/openapi/fog-1.6.json plus spec/overlay/fog-api-overlay.json into
the single flat spec every emitter reads.

.DESCRIPTION
Two inputs, and the split between them is the point.

spec/openapi/fog-1.6.json is FOG describing itself -- every path, method, field,
type, length, enum, required flag and permission. It is regenerated from a
fogproject checkout (spec/tools/dump-openapi.php) and never hand-edited, so it
cannot drift from the server.

spec/overlay/fog-api-overlay.json is the judgement: what FogApi calls things,
which operations earn a typed cmdlet, which functions are hand-written and stay
that way, and where FOG 1.5 differs. It is small on purpose.

This script does the mechanical part between them -- noun casing, pluralisation,
verb selection, folding count/names/ids/join onto their host cmdlets, resolving
each operation to an L1 call -- and writes spec/fog-api-spec.json. Emitters read
only that file, so a Python emitter never has to re-derive a naming rule
or re-read the OpenAPI document.

It validates rather than warns. Every one of these has bitten this repo or is
one rename away from doing so:

  - Every verb passes Get-Verb.
  - Every function name is unique across generated, thin-wrapper and
    hand-written sets.
  - Every hand-written and thin-wrapper name is a file that actually exists in
    FogApi/Public.
  - Every operationId an overlay entry claims exists in the snapshot.
  - Every tiered class exists in the snapshot, appears in exactly one tier, and
    every snapshot class is tiered.

A failure is a non-zero exit and no output file. A spec that builds but is wrong
is the failure mode worth spending strictness on: it becomes 300 wrong cmdlets.

.PARAMETER SpecRoot
The spec directory. Defaults to the one containing this script's parent.

.PARAMETER ModuleRoot
The FogApi module directory, used to confirm the registered functions exist.

.PARAMETER OutFile
Where to write the resolved spec. Defaults to spec/fog-api-spec.json.

.PARAMETER PassThru
Also emit the resolved spec object to the pipeline.

.EXAMPLE
./spec/tools/Build-FogApiSpec.ps1

Rebuilds spec/fog-api-spec.json and prints a summary.

.EXAMPLE
./spec/tools/Build-FogApiSpec.ps1 -PassThru | Select-Object -ExpandProperty stats

Rebuilds and inspects the counts without reading the file back.
#>
[CmdletBinding()]
param (
    [string]$SpecRoot = (Split-Path -Parent (Split-Path -Parent $PSCommandPath)),
    [string]$ModuleRoot,
    [string]$OutFile,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $ModuleRoot) {
    $ModuleRoot = Join-Path (Split-Path -Parent $SpecRoot) 'FogApi'
}
if (-not $OutFile) {
    $OutFile = Join-Path $SpecRoot 'fog-api-spec.json'
}

$script:Problems = [System.Collections.Generic.List[string]]::new()
function Add-Problem { param([string]$Message) $script:Problems.Add($Message) }

# --- inputs ---------------------------------------------------------------

$openApiPath = Join-Path (Join-Path $SpecRoot 'openapi') 'fog-1.6.json'
$overlayPath = Join-Path (Join-Path $SpecRoot 'overlay') 'fog-api-overlay.json'
foreach ($p in @($openApiPath, $overlayPath)) {
    if (-not (Test-Path -LiteralPath $p)) {
        throw "Missing spec input: $p"
    }
}

Write-Verbose "reading $openApiPath"
$oas = Get-Content -LiteralPath $openApiPath -Raw | ConvertFrom-Json
Write-Verbose "reading $overlayPath"
$overlay = Get-Content -LiteralPath $overlayPath -Raw | ConvertFrom-Json

# --- helpers --------------------------------------------------------------

function Get-OverlayKeys {
    <#
    Property names of an overlay object, minus the $comment/$schema annotations
    the file uses to document itself. JSON has no comments, so the convention is
    a $-prefixed key, and every walk over an overlay object has to skip them.
    #>
    param($Object)
    if ($null -eq $Object) { return @() }
    @($Object.PSObject.Properties.Name | Where-Object { $_ -notlike '$*' })
}

$approvedVerbs = @{}
Get-Verb | ForEach-Object { $approvedVerbs[$_.Verb] = $true }

$nounMap = @{}
foreach ($k in Get-OverlayKeys $overlay.naming.nouns) {
    $nounMap[$k] = $overlay.naming.nouns.$k
}
$pluralMap = @{}
foreach ($k in Get-OverlayKeys $overlay.naming.irregularPlurals) {
    $pluralMap[$k] = $overlay.naming.irregularPlurals.$k
}

function Resolve-Noun {
    <#
    The FogApi noun for a route class. Only irregular casings are listed in the
    overlay; anything else is the route name with its first letter capitalised,
    which is right for the 15 single-word classes and wrong for none of them.
    #>
    param([string]$Class)
    if ($nounMap.ContainsKey($Class)) { return $nounMap[$Class] }
    $Class.Substring(0, 1).ToUpperInvariant() + $Class.Substring(1)
}

function Resolve-PluralNoun {
    <#
    Plural list nouns are deliberate: Get-FogHosts, not Get-FogHost. It trips
    PSUseSingularNouns and matches the six list functions that already ship, so
    the analyzer rule is the thing that gives, not the convention.
    #>
    param([string]$Class)
    if ($pluralMap.ContainsKey($Class)) { return $pluralMap[$Class] }
    $noun = Resolve-Noun $Class
    if ($noun -cmatch '(s|x|z|ch|sh)$') { return $noun + 'es' }
    if ($noun -cmatch '[^aeiouAEIOU]y$') { return $noun.Substring(0, $noun.Length - 1) + 'ies' }
    $noun + 's'
}

function New-FunctionName {
    <#
    One rule, four renderings. Only the PowerShell rendering is built here; the
    spec stores verb and noun separately so the Python emitter derives
    their own rather than munging this string.
    #>
    param([string]$Verb, [string]$Noun, [string]$Infix = '', [string]$Suffix = '')
    '{0}-{1}{2}{3}{4}' -f $Verb, $Infix, $overlay.naming.prefix, $Noun, $Suffix
}

function Test-WriteOnlyField {
    <#
    A field the caller may send but never receives back -- writeOnly in
    OpenAPI's vocabulary, which this document does not use.

    FOG marks these readOnly instead, alongside the description "Never returned
    by the API." Those two statements are inverses of each other: readOnly means
    a field comes back in responses and must not be sent, writeOnly means it is
    sent and never comes back. The sentence is right and the flag is wrong.

    x-fog-server-owned separates the two cases and does it exactly:

      sensitive: always + server-owned  -> really readOnly. user.token is the
                                          one, and the server refuses a write.
      sensitive: always, not owned      -> really writeOnly. Exactly three:
                                          user.password, storagenode.pass and
                                          storagenode.key.

    Derived from the two markers rather than kept as a list of three names, so
    a sensitive field added upstream is classified without anyone remembering
    this function exists. The same reasoning Get-FogCoreObjectList records for
    its class list, where a hardcoded copy drifted by seven entries.
    #>
    param($Field)
    $names = $Field.PSObject.Properties.Name
    if (-not ($names -contains 'x-fog-sensitive')) { return $false }
    if ($Field.'x-fog-sensitive' -ne 'always') { return $false }
    if (($names -contains 'x-fog-server-owned') -and $Field.'x-fog-server-owned') { return $false }
    return $true
}

function Resolve-ComputedFields {
    <#
    The computed-field names out of a schema's description sentence.

    Parsing English is not something this pipeline should be doing, and it is
    here under protest: FOG names these fields in prose and nowhere else. The
    alternative is a hand-maintained list of 81 names across 24 classes, which
    would be wrong the first time upstream added a relation and would have no
    way to know.

    Anchored on the fixed clause _entitySchema() builds with sprintf, not on
    loose keyword matching, so a description that stops being generated this
    way yields nothing rather than yielding garbage. Build-FogApiSpec reports
    the total, and Tests/FogApiSpec.Tests.ps1 pins it -- a silent drop to zero
    is the failure mode worth catching, because nothing else would notice.
    #>
    param($Schema, [string[]]$DeclaredNames = @())
    if (-not ($Schema.PSObject.Properties.Name -contains 'description')) { return @() }
    $d = [string]$Schema.description
    if ($d -notmatch 'not settable through the generic create/edit path:\s*(.+?)\.(\s|$)') { return @() }
    $names = ($Matches[1] -split ',\s*') | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^[A-Za-z_][A-Za-z0-9_]*$' }
    # A name can be both. plugin.description is a real column AND listed as
    # computed, because the model overwrites it with the value read out of the
    # plugin's own metadata. The declared field wins: it is the one with a
    # type, and emitting both would be a duplicate member -- which in C# is a
    # compile error rather than something anyone would discover later.
    return @($names | Sort-Object -Unique | Where-Object { $DeclaredNames -notcontains $_ })
}

function Resolve-WireType {
    <#
    The one word an emitter needs to decide both a parameter's type and how the
    value goes on the wire. JSON type alone cannot say either, because FOG's
    booleans and timestamps are both spelled as strings.

    Six values, and the vocabulary is deliberately this small:

      bool01    A boolean the caller thinks in, transmitted as the STRING "0"
                or "1". Not the same as bool, and the distinction is the point:
                FOG spells every boolean column enum('0','1') -- 25 of them --
                and sending a JSON true is not the same request. FOG agrees
                these are booleans; snapinclient.class.php:204 casts one with
                (bool) to build the client payload.
      dateTime  An ISO timestamp. 16 fields. MySQL answers an unset datetime
                column with 0000-00-00 00:00:00, which is not a date and
                throws on a naive parse, so an emitter must map it to null.
      date      A date with no time. usertracking.date, and only that.
      int       A JSON number that is whole.
      number    A JSON number that is not. None today; here so the mapping is
                total rather than "everything else is a string".
      string    Everything else, including the three real string enums
                (powermanagement.action, tasktype.type, tasktype.access) whose
                enum list already carries the constraint.

    Derived, with no hand-maintained list behind it. That was not the plan --
    a fieldTypes block in the overlay was, for the date columns FOG does not
    type. Measuring the residual found there are none. Every string field whose
    NAME suggests a timestamp is something else: host.pingstatus and
    .pingmethod are status codes, hostautologout.time and snapin.timeout are
    durations in minutes and seconds, task.timeElapsed and .timeRemaining are
    elapsed spans, inventory.biosdate is whatever dmidecode printed.

    scheduledtask.scheduleTime is the one that looks like a real exception --
    bigint(20) unsigned, column stDateTime -- and it is not typed here on
    purpose. ScheduledTask::getTimer() feeds it in as a cron MINUTE for a
    non-cron task and formats it as a date elsewhere. It is overloaded
    upstream, and the wider domain is the safe mapping: the same rule that
    deploySnapins taught, where reading a -1 as a boolean silently queued a
    different snapin task.

    So an overlay block would have shipped with nothing in it. If a genuine
    override ever appears, this is the function that grows the lookup.
    #>
    param($Field)
    $names = $Field.PSObject.Properties.Name

    if ($names -contains 'enum') {
        $values = @($Field.enum) | ForEach-Object { [string]$_ }
        if ($values.Count -eq 2 -and ($values | Sort-Object) -join '|' -eq '0|1') { return 'bool01' }
    }
    if ($names -contains 'format') {
        switch ($Field.format) {
            'date-time' { return 'dateTime' }
            'date'      { return 'date' }
        }
    }
    $type = if ($names -contains 'type') { $Field.type } else { 'string' }
    switch ($type) {
        'integer' { return 'int' }
        'number'  { return 'number' }
        'boolean' { return 'bool' }
        default   { return 'string' }
    }
}

# --- index the snapshot ---------------------------------------------------

# operationId -> { path, method, class, routeName, operation }
$operations = @{}
$classOperations = @{}

foreach ($pathProp in $oas.paths.PSObject.Properties) {
    $path = $pathProp.Name
    foreach ($methodProp in $pathProp.Value.PSObject.Properties) {
        $method = $methodProp.Name
        if ($method -eq 'parameters') { continue }
        $op = $methodProp.Value
        $class = $op.tags[0]
        $opId = $op.operationId

        # _op() builds operationId as routeName + ucfirst(class) for the generic
        # per-class shapes, so the route name is recoverable by stripping the
        # class suffix. System routes carry the route name alone.
        #
        # Two operations are tagged with a class but do not follow that pattern:
        # snapinCreateWithFile and uploadSnapinFiles are fixed paths that happen
        # to live under a class tag for grouping. A mismatch is therefore the
        # signal for "literal route", not an error -- these are tier 5, named
        # individually, because a fixed path has no class shape to derive from.
        $routeName = $opId
        $literalRoute = $false
        if ($class -ne 'system') {
            $suffix = $class.Substring(0, 1).ToUpperInvariant() + $class.Substring(1)
            if ($opId.EndsWith($suffix)) {
                $routeName = $opId.Substring(0, $opId.Length - $suffix.Length)
            } else {
                $literalRoute = $true
            }
        }

        if ($operations.ContainsKey($opId)) {
            Add-Problem "duplicate operationId '$opId' ($path $method)"
        }
        $operations[$opId] = [pscustomobject]@{
            operationId = $opId
            path        = $path
            method      = $method.ToUpperInvariant()
            class       = $class
            routeName   = $routeName
            literalRoute = $literalRoute
            summary     = $op.summary
            permission  = $(if ($op.PSObject.Properties.Name -contains 'x-fog-permission') { $op.'x-fog-permission' } else { $null })
        }
        if ($class -ne 'system' -and -not $literalRoute) {
            if (-not $classOperations.ContainsKey($class)) {
                $classOperations[$class] = @{}
            }
            $classOperations[$class][$routeName] = $opId
        }
    }
}

$snapshotClasses = @($oas.tags | Where-Object { $_.name -ne 'system' } | ForEach-Object { $_.name } | Sort-Object)

# --- entity schemas -------------------------------------------------------

# Class -> field list, straight from the document. This is what makes typed
# parameters possible at all: property name, JSON type, the raw column name it
# maps to, length, enum values, whether the server sets it, whether it is
# required on create.
# Ordered, and populated in sorted class order, because ConvertTo-Json emits a
# plain hashtable in whatever order it enumerates. That makes the output differ
# run to run, which turns the staleness test into a coin flip and every rebuild
# into an unreadable diff.
$schemaByClass = [ordered]@{}
foreach ($class in $snapshotClasses) {
    $schemaName = ($class.Substring(0, 1).ToUpperInvariant() + $class.Substring(1))
    if (-not ($oas.components.schemas.PSObject.Properties.Name -contains $schemaName)) {
        Add-Problem "no component schema '$schemaName' for class '$class'"
        continue
    }
    $schema = $oas.components.schemas.$schemaName
    $required = @()
    if ($schema.PSObject.Properties.Name -contains 'required') { $required = @($schema.required) }
    $fields = foreach ($prop in $schema.properties.PSObject.Properties) {
        $f = $prop.Value
        [pscustomobject][ordered]@{
            name     = $prop.Name
            type     = $(if ($f.PSObject.Properties.Name -contains 'type') { $f.type } else { 'string' })
            # OpenAPI qualifies `type: string` with `format`, and FOG populates it:
            # _columnSchema() maps a datetime/timestamp column to string/date-time
            # and a date column to string/date. Seventeen fields carry one --
            # host.deployed (hostLastDeploy), host.lastcheckin, task.checkInTime,
            # multicastsession.starttime, usertracking.date and twelve more.
            #
            # This line is the fix for having dropped it. Every emitter has been
            # reading those seventeen as a bare string, because `type` alone was
            # carried across and `format` is where the whole distinction lives. A
            # date is not a string that happens to look like one: the PowerShell
            # emitter typed all seventeen [string], and a typed model cannot be
            # generated at all without this.
            #
            # Carried raw rather than resolved, so it traces straight back to the
            # snapshot. FogApi's decision about what to DO with it belongs in the
            # overlay, not here.
            format   = $(if ($f.PSObject.Properties.Name -contains 'format') { $f.format } else { $null })
            # type + format + enum resolved into the one word an emitter acts
            # on. Resolved here rather than in each emitter so PowerShell,
            # Python cannot reach three different answers about
            # whether host.pending is a boolean.
            wireType = Resolve-WireType $f
            column   = $(if ($f.PSObject.Properties.Name -contains 'x-fog-column') { $f.'x-fog-column' } else { $null })
            nullable = [bool]($f.PSObject.Properties.Name -contains 'nullable' -and $f.nullable)
            # readOnly, corrected -- see writeOnly below for why it needs to be.
            readOnly = [bool](
                ($f.PSObject.Properties.Name -contains 'readOnly' -and $f.readOnly) -and
                -not (Test-WriteOnlyField $f)
            )
            # A field the caller may SEND but never receives back.
            #
            # FOG marks these readOnly, which is backwards. In OpenAPI 3,
            # readOnly means "returned in responses, never sent in requests";
            # writeOnly is the inverse. _entitySchema() maps
            # x-fog-sensitive: always to readOnly with the description
            # "Never returned by the API." -- which is the definition of
            # writeOnly, so the flag and the sentence next to it contradict
            # each other. The document uses writeOnly nowhere.
            #
            # It is not cosmetic. The emitter skips readOnly fields, so the
            # server's own document was removing the credential parameters
            # from the cmdlets that exist to set them: New-FogStorageNode has
            # no -pass and no -key today, and a storage node without its FTP
            # credentials does not work. user.password was writable when the
            # snapshot was last taken and turned readOnly by 1.6.0-beta.4013,
            # so a re-snapshot would have taken -password off New-FogUser and
            # left no way to create a usable account.
            #
            # route.class.php:358 says so outright, listing what is
            # deliberately NOT server-owned: "Nor user.password: User::set()
            # hashes it, so a supplied one is a real and supported write."
            #
            # x-fog-server-owned is the discriminator, and it is exact.
            # user.token is BOTH sensitive-always and server-owned, and is
            # genuinely readOnly; flipping on sensitivity alone would have
            # added a -token parameter the server refuses. Derived rather
            # than listed, so a sensitive field added upstream is classified
            # without anyone remembering to come back here.
            writeOnly = [bool](Test-WriteOnlyField $f)
            # Carried through so an emitter can act on them: a writeOnly field
            # must not become a model property that expects to round-trip, and
            # a sensitive one must not be echoed into a log or an example.
            sensitive   = $(if ($f.PSObject.Properties.Name -contains 'x-fog-sensitive') { $f.'x-fog-sensitive' } else { $null })
            serverOwned = [bool]($f.PSObject.Properties.Name -contains 'x-fog-server-owned' -and $f.'x-fog-server-owned')
            maxLength = $(if ($f.PSObject.Properties.Name -contains 'maxLength') { $f.maxLength } else { $null })
            # A model constraint the column type does not carry -- host.name is
            # varchar(16) but Host::isHostnameSafe() allows 15 and a charset.
            # The emitter turns it into ValidatePattern, so a caller is told
            # before the request rather than by a 406 that names no field.
            pattern  = $(if ($f.PSObject.Properties.Name -contains 'pattern') { $f.pattern } else { $null })
            enum     = $(if ($f.PSObject.Properties.Name -contains 'enum') { @($f.enum) } else { $null })
            required = ($required -contains $prop.Name)
            aliases  = @()
        }
    }
    $schemaByClass[$class] = [pscustomobject][ordered]@{
        schemaName = $schemaName
        table      = $(if ($schema.PSObject.Properties.Name -contains 'x-fog-table') { $schema.'x-fog-table' } else { $null })
        fields     = @($fields)
        # Fields a response can carry that are NOT columns and are not in
        # properties. host declares 33 and answers with more: mac, primac,
        # groups, snapins, inventory, task and ten others.
        #
        # _entitySchema() reflects a model's $databaseFields -- its own columns
        # -- while the route returns the entity joined to its relations. FOG
        # knows the difference and says so, but only in English, in the schema
        # description: "Responses may carry computed fields that are not
        # columns and are not settable through the generic create/edit path:
        # ...". The names are there; nothing structured carries them.
        #
        # Read here rather than added to the snapshot, because the snapshot is
        # a faithful copy of what the server serves and is verified byte for
        # byte against a live one. Teaching the dump to emit more than FOG does
        # would destroy the only check that says the copy is honest. So the
        # snapshot stays what FOG said, and this is FogApi reading it.
        #
        # Names only, no types, because FOG declares none -- and several are
        # whole nested entities rather than scalars, so a type here would be a
        # guess. Enough for an emitter to declare the member and stop
        # ConvertTo-Json dropping it; typing individual ones is a later and
        # separate decision.
        #
        # The real fix is upstream: emit these as readOnly properties, at which
        # point this parse finds the same names in a better place and can go.
        computed   = @(Resolve-ComputedFields -Schema $schema -DeclaredNames @($fields.name))
    }
}

# --- tiers ----------------------------------------------------------------

$tierOfClass = @{}
$tierDefs = @{}
foreach ($tierKey in Get-OverlayKeys $overlay.tiers) {
    $tier = $overlay.tiers.$tierKey
    if (-not ($tier.PSObject.Properties.Name -contains 'classes')) { continue }
    $tierDefs[$tierKey] = @($tier.operations)
    foreach ($class in $tier.classes) {
        if ($tierOfClass.ContainsKey($class)) {
            Add-Problem "class '$class' is in tier $($tierOfClass[$class]) and tier $tierKey; it must be in exactly one"
        }
        if ($snapshotClasses -notcontains $class) {
            Add-Problem "tier $tierKey lists class '$class', which the snapshot does not have. Either it was renamed upstream or it is a typo."
        }
        $tierOfClass[$class] = $tierKey
    }
}
foreach ($class in $snapshotClasses) {
    if (-not $tierOfClass.ContainsKey($class)) {
        Add-Problem "class '$class' exists in the snapshot but is in no tier. Every class needs a decision, even if the decision is 'read-only lookup'."
    }
}

# --- existing functions ---------------------------------------------------

$publicDir = Join-Path $ModuleRoot 'Public'
$existingFunctions = @{}
$existingAliases = @{}
if (Test-Path -LiteralPath $publicDir) {
    foreach ($file in (Get-ChildItem -LiteralPath $publicDir -Filter '*.ps1')) {
        $existingFunctions[$file.BaseName] = $true
        # Aliases count as claimed names too. A generated cmdlet cannot take a
        # name an alias already occupies -- Get-FogGroup is an alias for
        # Get-FogHostGroup today, and emitting a function by that name would
        # collide at import. Read from the AST rather than by line position, so
        # this sees an alias wherever it is legally declared.
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $file.FullName, [ref]$null, [ref]$parseErrors)
        if ($parseErrors -and $parseErrors.Count -gt 0) { continue }
        foreach ($attr in $ast.FindAll({
                param($node) $node -is [System.Management.Automation.Language.AttributeAst] -and
                    $node.TypeName.Name -eq 'Alias' }, $true)) {
            if ($attr.Parent -isnot [System.Management.Automation.Language.ParamBlockAst]) { continue }
            foreach ($arg in $attr.PositionalArguments) {
                if ($arg -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                    $existingAliases[$arg.Value] = $file.BaseName
                }
            }
        }
    }
} else {
    Add-Problem "module Public directory not found at $publicDir"
}

$handWritten = @{}
foreach ($name in Get-OverlayKeys $overlay.handWritten) {
    $entry = $overlay.handWritten.$name
    # implementation: "compiled" means the command is a cmdlet in FogApi.dll
    # rather than a file in Public/, so there is no .ps1 to look for. Still
    # registered here: the coverage matrix has to count it as covered, and the
    # python emitter still owes an implementation of it -- what moved
    # is the language, not the obligation.
    $implementation = if ($entry.PSObject.Properties.Name -contains 'implementation') { $entry.implementation } else { 'script' }
    if ($implementation -notin @('script', 'compiled')) {
        Add-Problem "overlay entry '$name' has implementation '$implementation'; expected 'script' or 'compiled'"
    }
    if ($implementation -eq 'script' -and -not $existingFunctions.ContainsKey($name)) {
        Add-Problem "overlay registers hand-written function '$name', but FogApi/Public/$name.ps1 does not exist"
    }
    if ($implementation -eq 'compiled' -and $existingFunctions.ContainsKey($name)) {
        # Both would exist, and a function beats a cmdlet in PowerShell's
        # resolution order -- so the .ps1 would silently win and the compiled
        # one would be dead code. Measured: it happened, and the .ps1 reached
        # the network because it knows nothing about the transport seam.
        Add-Problem "overlay marks '$name' compiled, but FogApi/Public/$name.ps1 still exists; the function would shadow the cmdlet"
    }
    $handWritten[$name] = $entry
}

$thinWrappers = @{}
foreach ($name in Get-OverlayKeys $overlay.thinWrappers) {
    $entry = $overlay.thinWrappers.$name
    # A thin wrapper is registered so the generator knows the name is taken and
    # can keep it as an alias. Once the generated command HAS replaced it, the
    # .ps1 is gone on purpose -- that is what status 'replaces-thin-wrapper'
    # means, and a compiled cmdlet cannot coexist with a function of the same
    # name anyway, because the function would shadow it. So a missing file is
    # only a problem while the replacement has not been emitted.
    $compiled = Test-Path -LiteralPath (Join-Path (Split-Path -Parent $ModuleRoot) 'src' 'FogApi.Cmdlets' 'Cmdlets' 'Generated' "$($name -replace '-', '')Command.cs")
    if (-not $existingFunctions.ContainsKey($name) -and -not $compiled) {
        Add-Problem "overlay registers thin wrapper '$name', but neither FogApi/Public/$name.ps1 nor a generated cmdlet for it exists"
    }
    if (-not $operations.ContainsKey($entry.operation)) {
        Add-Problem "thin wrapper '$name' claims operation '$($entry.operation)', which is not in the snapshot"
    }
    $thinWrappers[$name] = $entry
}

# --- resolve the generated set -------------------------------------------

$folded = @{}
foreach ($rn in Get-OverlayKeys $overlay.naming.foldedOperations) {
    $folded[$rn] = $overlay.naming.foldedOperations.$rn
}
$opNaming = @{}
foreach ($rn in Get-OverlayKeys $overlay.naming.operations) {
    $opNaming[$rn] = $overlay.naming.operations.$rn
}

# Parameter aliases, resolved per class. Validated here rather than trusted:
# an alias that collides with a real parameter name silently shadows nothing and
# fails at import, and one naming a field the class does not have is a typo that
# would otherwise just never appear.
$paramAliasCommon = @{}
if ($overlay.PSObject.Properties.Name -contains 'parameterAliases') {
    foreach ($k in Get-OverlayKeys $overlay.parameterAliases.common) {
        $paramAliasCommon[$k] = @($overlay.parameterAliases.common.$k)
    }
    foreach ($cls in Get-OverlayKeys $overlay.parameterAliases.byClass) {
        if ($snapshotClasses -notcontains $cls) {
            Add-Problem "parameterAliases.byClass names class '$cls', which the snapshot does not have"
            continue
        }
        $fieldNames = @($schemaByClass[$cls].fields | ForEach-Object { $_.name })
        foreach ($field in Get-OverlayKeys $overlay.parameterAliases.byClass.$cls) {
            if ($fieldNames -notcontains $field) {
                Add-Problem "parameterAliases.byClass.$cls names field '$field', which is not a field of that class"
                continue
            }
            foreach ($alias in @($overlay.parameterAliases.byClass.$cls.$field)) {
                if ($fieldNames -contains $alias) {
                    Add-Problem "parameterAliases.byClass.$cls.$field aliases '$alias', which is already a real field on that class"
                }
            }
        }
    }
}

function Resolve-ParameterAliases {
    <#
    Every alias for one parameter of one class: the common ones plus that
    class's own, deduplicated and in a stable order so the spec stays
    byte-identical between runs.
    #>
    param([string]$Class, [string]$Parameter)
    $all = [System.Collections.Generic.List[string]]::new()
    if ($paramAliasCommon.ContainsKey($Parameter)) {
        foreach ($a in $paramAliasCommon[$Parameter]) { $all.Add($a) }
    }
    $byClass = $overlay.parameterAliases.byClass
    if ($byClass -and ($byClass.PSObject.Properties.Name -contains $Class)) {
        $forClass = $byClass.$Class
        if ($forClass.PSObject.Properties.Name -contains $Parameter) {
            foreach ($a in @($forClass.$Parameter)) { $all.Add($a) }
        }
    }
    @($all | Select-Object -Unique)
}

$fifteenAbsentOps = @($overlay.fifteen.absentOperations)
$fifteenAbsentClasses = @($overlay.fifteen.absentClasses.classes)
$fifteenSpellings = @{}
foreach ($rn in Get-OverlayKeys $overlay.fifteen.routeSpellings) {
    $fifteenSpellings[$rn] = $overlay.fifteen.routeSpellings.$rn
}

# operation -> which L1 wrapper carries it
$l1For = @{
    list   = 'Get-FogObject'
    indiv  = 'Get-FogObject'
    active = 'Get-FogObject'
    search = 'Find-FogObject'
    create = 'New-FogObject'
    update = 'Update-FogObject'
    delete = 'Remove-FogObject'
    task   = 'New-FogObject'
    cancel = 'Remove-FogObject'
}

# Filled after the alias tables are built, because validating an alias needs the
# field list the schema pass produces.
foreach ($class in $snapshotClasses) {
    if (-not $schemaByClass.Contains($class)) { continue }
    foreach ($field in $schemaByClass[$class].fields) {
        $field.aliases = @(Resolve-ParameterAliases -Class $class -Parameter $field.name)
    }
}

$generated = [System.Collections.Generic.List[object]]::new()
# Seeded from the overlay, not from the files in Public. A name is "taken" only
# when a human owns it; seeding from disk would make the emitter's own output
# from a previous run look like a hand-written claim and skip regenerating it,
# which quietly freezes every generated cmdlet after its first emit.
$claimedNames = @{}
foreach ($name in $handWritten.Keys) { $claimedNames[$name] = 'hand-written' }
foreach ($name in $thinWrappers.Keys) { $claimedNames[$name] = 'thin-wrapper' }
# An alias occupies a name as surely as a function does.
foreach ($name in $existingAliases.Keys) {
    if (-not $claimedNames.ContainsKey($name)) { $claimedNames[$name] = 'alias' }
}

$thinWrapperOps = @{}
foreach ($name in $thinWrappers.Keys) { $thinWrapperOps[$thinWrappers[$name].operation] = $name }

foreach ($class in $snapshotClasses) {
    $tierKey = $tierOfClass[$class]
    if (-not $tierDefs.ContainsKey($tierKey)) { continue }
    $wanted = $tierDefs[$tierKey]
    foreach ($routeName in $wanted) {
        if (-not $classOperations[$class].ContainsKey($routeName)) {
            # Not an error: tier 1 asks for task/cancel/active, and only the
            # eight tasking classes have them.
            continue
        }
        # An operation that merges into another names no function of its own.
        # 'list' merges into 'indiv' because Get-Fog{Noun} answers both -- no
        # arguments returns everything, -id or -name narrows to one -- so the
        # list operation is recorded on that function rather than beside it.
        if ($opNaming[$routeName].PSObject.Properties.Name -contains 'mergesInto') {
            continue
        }
        $opId = $classOperations[$class][$routeName]
        $naming = $opNaming[$routeName]
        if ($null -eq $naming) {
            Add-Problem "no naming rule for route '$routeName' (needed by $opId)"
            continue
        }
        if (-not $approvedVerbs.ContainsKey($naming.verb)) {
            Add-Problem "verb '$($naming.verb)' for route '$routeName' is not an approved PowerShell verb"
            continue
        }
        $noun = if ($naming.nounForm -eq 'plural') { Resolve-PluralNoun $class } else { Resolve-Noun $class }
        $infix = if ($naming.PSObject.Properties.Name -contains 'infix') { $naming.infix } else { '' }
        $suffix = if ($naming.PSObject.Properties.Name -contains 'suffix') { $naming.suffix } else { '' }
        $fn = New-FunctionName -Verb $naming.verb -Noun $noun -Infix $infix -Suffix $suffix

        # Operations that merge into this one, so the emitter knows which
        # parameter sets to build and the coverage matrix can score them as
        # covered rather than missing.
        $mergedOps = @()
        foreach ($otherRoute in $opNaming.Keys) {
            $otherNaming = $opNaming[$otherRoute]
            if ($otherNaming.PSObject.Properties.Name -notcontains 'mergesInto') { continue }
            if ($otherNaming.mergesInto -ne $routeName) { continue }
            if (-not $classOperations[$class].ContainsKey($otherRoute)) { continue }
            $mergedOps += $classOperations[$class][$otherRoute]
        }

        $status = 'generate'
        $aliases = @()
        $replaces = $null
        $blockedBy = $null
        # The plural spelling this function replaces. Kept as an alias so
        # Get-FogHosts and its siblings keep working; it is not the function
        # name any more.
        if ($naming.PSObject.Properties.Name -contains 'pluralAlias' -and $naming.pluralAlias) {
            $pluralName = New-FunctionName -Verb $naming.verb -Noun (Resolve-PluralNoun $class) -Infix $infix -Suffix $suffix
            if ($pluralName -ne $fn) { $aliases += $pluralName }
        }
        $wrapperOpId = $opId
        if (-not $thinWrapperOps.ContainsKey($wrapperOpId)) {
            # A merged operation can be the one an existing wrapper covers:
            # Get-FogHosts stands in for listHost, which now belongs to
            # Get-FogHost rather than to a function of its own.
            foreach ($m in $mergedOps) {
                if ($thinWrapperOps.ContainsKey($m)) { $wrapperOpId = $m; break }
            }
        }
        if ($claimedNames[$fn] -eq 'alias') {
            # Skipped rather than emitted: the name belongs to an alias of some
            # other function, so emitting it would collide at import. Freeing
            # the name is a decision for whoever owns that alias.
            $status = 'skipped-name-taken'
            $blockedBy = $existingAliases[$fn]
        } elseif ($claimedNames[$fn] -eq 'hand-written') {
            # A hand-written function owns this name, so it wins outright --
            # checked BEFORE the thin-wrapper branch, because a merged operation
            # can match a wrapper while the merged NAME belongs to something
            # hand-written. Get-FogHost is the case: it identifies the local
            # machine when given nothing, Get-FogHosts is a thin wrapper for
            # listHost, and without this order the generated Get-FogHost would
            # claim to replace the wrapper and quietly displace the hand-written
            # local-machine behaviour.
            $status = 'skipped-name-taken'
        } elseif ($thinWrapperOps.ContainsKey($wrapperOpId)) {
            # An existing wrapper already covers this operation. The generated
            # name wins where they differ and the old name becomes an alias;
            # nothing is deleted, so no caller breaks.
            $replaces = $thinWrapperOps[$wrapperOpId]
            if ($replaces -ne $fn) { $aliases = @($replaces) }
            $status = 'replaces-thin-wrapper'
        } elseif ($claimedNames.ContainsKey($fn)) {
            # A hand-written function already owns this name. Skip rather than
            # collide -- Get-FogHost is the standing example: it identifies the
            # local machine when given nothing, which no generated cmdlet does.
            $status = 'skipped-name-taken'
        }

        $op = $operations[$opId]
        $onFifteen = -not ($fifteenAbsentOps -contains $routeName -or $fifteenAbsentClasses -contains $class)
        $fifteenPath = $null
        if ($onFifteen -and $fifteenSpellings.ContainsKey($routeName)) {
            $fifteenPath = $fifteenSpellings[$routeName]
        }

        $generated.Add([pscustomobject]@{
            functionName  = $fn
            status        = $status
            blockedBy     = $blockedBy
            replaces      = $replaces
            aliases       = $aliases
            suppressedAliases = @()
            verb          = $naming.verb
            noun          = "$infix$($overlay.naming.prefix)$noun$suffix"
            operationId   = $opId
            routeName     = $routeName
            mergedOperations = @($mergedOps)
            class         = $class
            tier          = $tierKey
            method        = $op.method
            path          = $op.path
            permission    = $op.permission
            summary       = $op.summary
            l1Function    = $(if ($l1For.ContainsKey($routeName)) { $l1For[$routeName] } else { $null })
            coreObject    = $class
            schema        = $(if ($schemaByClass.Contains($class)) { $schemaByClass[$class].schemaName } else { $null })
            onFogFifteen  = $onFifteen
            fifteenPath   = $fifteenPath
        })
        if ($status -eq 'generate' -or $status -eq 'replaces-thin-wrapper') {
            if ($claimedNames.ContainsKey($fn) -and $status -eq 'generate') {
                Add-Problem "generated name collision on '$fn' (from $opId)"
            }
            $claimedNames[$fn] = $opId
        }
    }
}

# --- tier 5 fixed routes -------------------------------------------------

$fixed = [System.Collections.Generic.List[object]]::new()
foreach ($routeName in Get-OverlayKeys $overlay.tiers.'5'.operations) {
    $entry = $overlay.tiers.'5'.operations.$routeName
    if (-not $operations.ContainsKey($routeName)) {
        Add-Problem "tier 5 lists route '$routeName', which is not an operationId in the snapshot"
        continue
    }
    $op = $operations[$routeName]
    $verb = $entry.function.Split('-')[0]
    if (-not $approvedVerbs.ContainsKey($verb)) {
        Add-Problem "tier 5 function '$($entry.function)' uses unapproved verb '$verb'"
    }
    $fixed.Add([pscustomobject]@{
        functionName = $entry.function
        operationId  = $routeName
        method       = $op.method
        path         = $op.path
        permission   = $op.permission
        summary      = $op.summary
        tier         = '5'
        existing     = $(if ($entry.PSObject.Properties.Name -contains 'existing') { $entry.existing } else { $null })
        note         = $(if ($entry.PSObject.Properties.Name -contains 'note') { $entry.note } else { $null })
        # Fixed routes have no L1 representation, which is the one sanctioned
        # reason to call the transport directly.
        l1Function   = $null
    })
}

# --- an alias must never shadow a generated function ---------------------

# A thin wrapper's old name becomes an alias on whatever replaced it, which is
# how callers keep working. That is wrong when the same name is ALSO a generated
# function: Get-FogSetting was the search wrapper's name, so Find-FogSetting
# claimed it as an alias -- and shadowed the real generated Get-FogSetting,
# which then answered as a search and refused -settingName. The alias wins at
# resolution time, so the collision is silent until something calls it.
$generatedNameSet = @{}
foreach ($fn in $generated) {
    if ($fn.status -in @('generate', 'replaces-thin-wrapper')) { $generatedNameSet[$fn.functionName] = $true }
}
foreach ($fn in $generated) {
    if (-not $fn.aliases -or $fn.aliases.Count -eq 0) { continue }
    $kept = @()
    foreach ($alias in $fn.aliases) {
        if ($generatedNameSet.ContainsKey($alias) -and $alias -ne $fn.functionName) {
            # Dropped, not an error: the function of that name is the better
            # answer for a caller typing it, and it is emitted either way.
            $fn.suppressedAliases = @($fn.suppressedAliases) + $alias
            continue
        }
        $kept += $alias
    }
    $fn.aliases = @($kept)
}

# --- every file in Public is accounted for -------------------------------

# Checked here rather than alongside the overlay reads, because a file the
# emitter produced is accounted for by the spec itself and needs no overlay
# entry. Running this before the generated set was resolved flagged every
# emitted file as unclassified.
$generatedNames = @{}
foreach ($fn in $generated) { $generatedNames[$fn.functionName] = $true }
foreach ($fx in $fixed) { $generatedNames[$fx.functionName] = $true }
foreach ($name in $existingFunctions.Keys) {
    if ($handWritten.ContainsKey($name)) { continue }
    if ($thinWrappers.ContainsKey($name)) { continue }
    if ($generatedNames.ContainsKey($name)) { continue }
    Add-Problem "FogApi/Public/$name.ps1 exists but nothing accounts for it: it is not in the overlay's handWritten or thinWrappers, and the spec does not generate a function by that name. Classify it in the overlay, or delete it if the emitter no longer produces it."
}

# --- report --------------------------------------------------------------

if ($script:Problems.Count -gt 0) {
    Write-Host ''
    Write-Host "Build-FogApiSpec found $($script:Problems.Count) problem(s):" -ForegroundColor Red
    $script:Problems | Sort-Object -Unique | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ''
    throw "spec not written: $($script:Problems.Count) problem(s) above"
}

$toGenerate = @($generated | Where-Object { $_.status -in @('generate', 'replaces-thin-wrapper') })

$spec = [ordered]@{
    '$comment'   = @(
        'GENERATED FILE. Do not edit.',
        'Rebuild with spec/tools/Build-FogApiSpec.ps1 after changing either input.',
        'Inputs: spec/openapi/fog-1.6.json (regenerated from fogproject) and',
        'spec/overlay/fog-api-overlay.json (hand-maintained decisions).',
        'Every emitter -- PowerShell and Python -- reads this file and nothing else.'
    )
    specVersion  = 1
    source       = [ordered]@{
        openapi     = 'spec/openapi/fog-1.6.json'
        fogVersion  = $oas.info.version
        overlay     = 'spec/overlay/fog-api-overlay.json'
        oasVersion  = $oas.openapi
    }
    paging       = $oas.'x-fog-paging'
    security     = [ordered]@{
        headers = @('fog-api-token', 'fog-user-token')
        note    = 'Both tokens are already base64 as issued by the web UI. Send them verbatim; encoding them again double-encodes and 401s every call.'
        unauthenticatedRoutes = @('/system/status', '/system/info', '/system/openapi', '/swagger.json')
        # Read from the snapshot rather than listed here, so a scheme added
        # upstream shows up without anyone editing this file. bearerAuth
        # arrived exactly that way, in 1.6.0-beta.4013.
        schemes = @($oas.components.securitySchemes.PSObject.Properties.Name | Sort-Object)
        # Each entry is one acceptable combination; within an entry every named
        # scheme is required together. Two things changed in beta.4013 and only
        # one of them is the new scheme: bearerAuth is accepted ALONE, and
        # basicAuth alone no longer is -- it now needs the server-wide
        # fog-api-token beside it.
        accepts = @(
            foreach ($alt in $oas.security) { , @($alt.PSObject.Properties.Name | Sort-Object) }
        )
        bearer = [ordered]@{
            header = 'Authorization: Bearer <token>'
            note   = @(
                'Sufficient on its own -- no fog-api-token header beside it.',
                'ADR 0027: a Bearer credential is a row in apiTokens, not a second spelling of users.uAPIToken. SHA-256 hashed at rest, shown once at creation, individually revocable, many per user, and prefixed fog_ so a leaked-credential scanner has something to match.',
                'users.uAPIToken is untouched and keeps working as fog-user-token beside fog-api-token, so nothing FogApi sends today has to change.',
                'UPSTREAM DESCRIPTION IS STALE: openapi.class.php still describes bearerAuth as "The per-user API token from the API tab ... Sufficient on its own", which is what 420623b2a shipped and ed597ef8a withdrew. Do not generate guidance from that sentence.'
            )
        }
    }
    fifteen      = $overlay.fifteen
    stats        = [ordered]@{
        snapshotClasses    = $snapshotClasses.Count
        snapshotOperations = $operations.Count
        tieredClasses      = $tierOfClass.Count
        candidateOps       = $generated.Count
        toGenerate         = $toGenerate.Count
        skippedNameTaken   = @($generated | Where-Object { $_.status -eq 'skipped-name-taken' }).Count
        replacesThinWrapper = @($generated | Where-Object { $_.status -eq 'replaces-thin-wrapper' }).Count
        fixedRoutes        = $fixed.Count
        handWritten        = $handWritten.Count
        # Counted so a silent drop to zero is visible. These names are parsed
        # out of an English sentence FOG writes, so the way this breaks is the
        # sentence being reworded upstream -- which yields no names and no
        # error. A number in the report and a floor in the suite are the only
        # things that would notice.
        declaredFields     = @($schemaByClass.Values.fields).Count
        computedFields     = @($schemaByClass.Values | ForEach-Object { $_.computed }).Count
    }
    functions    = @($generated)
    fixedRoutes  = @($fixed)
    handWritten  = $overlay.handWritten
    thinWrappers = $overlay.thinWrappers
    schemas      = $schemaByClass
    folded       = $overlay.naming.foldedOperations
    parameterAliases = $overlay.parameterAliases
}

$json = $spec | ConvertTo-Json -Depth 12
Set-Content -LiteralPath $OutFile -Value $json -Encoding utf8

Write-Host "wrote $OutFile"
Write-Host ("  snapshot: {0} classes, {1} operations" -f $spec.stats.snapshotClasses, $spec.stats.snapshotOperations)
Write-Host ("  generated: {0} functions ({1} replace a thin wrapper, {2} skipped because a hand-written function owns the name)" -f `
    $spec.stats.toGenerate, $spec.stats.replacesThinWrapper, $spec.stats.skippedNameTaken)
Write-Host ("  hand-written: {0}   fixed routes: {1}" -f $spec.stats.handWritten, $spec.stats.fixedRoutes)
Write-Host ("  fields: {0} declared, {1} computed (named in prose, not in properties)" -f $spec.stats.declaredFields, $spec.stats.computedFields)

if ($PassThru) { [pscustomobject]$spec }
