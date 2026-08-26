<#
.SYNOPSIS
Emits the C# entity models and cmdlets from spec/fog-api-spec.json.

.DESCRIPTION
The C# emitter. A sibling of New-FogApiFunctionFile.ps1, not a replacement for
it in principle: both read the resolved spec and nothing else, which is what
makes a Python emitter another sibling rather than a rewrite.

It is written in PowerShell rather than C# on purpose. A C# generator would
need the .NET SDK installed to regenerate the code the SDK then compiles, and
every other tool in spec/tools already runs anywhere pwsh does. The emitter's
language has nothing to do with the output's.

WHY NOT openapi-generator OR KIOTA

Neither emits PowerShell cmdlets at all, so all 161 would still be hand-written
over whatever client they produced. Neither knows the overlay -- the verb and
noun, the tiers, which operations fold into switches, which names a hand-written
function already owns, the parameter aliases -- and that judgement is the whole
product. FOG's operationIds are the router's internal names (indivHost,
namesHost, activeTask), so a generator names methods after the router rather
than after PowerShell.

The deciding one: their models drop the fields FOG returns but does not declare.
Kiota's answer is AdditionalData, an IDictionary<string,object>, and that was
MEASURED not to satisfy PowerShell member access -- $h.macs comes back $null.
It fails the exact requirement that made C# the right call.

And a C# path generated from raw swagger.json would make C# the one target that
reads a different source from Python, which is the divergence this
whole effort exists to prevent.

.PARAMETER Class
Emit only these route classes. Omit for everything the spec specifies.

.PARAMETER OutRoot
Where src/FogApi.Cmdlets lives. Defaults to the repo's own.

.PARAMETER DocsOut
Where the PlatyPS markdown goes. Defaults to docs/commands.

.PARAMETER NoDocs
Skip the markdown.

.EXAMPLE
./spec/tools/New-FogCmdletSource.ps1 -Class printer

.EXAMPLE
./spec/tools/New-FogCmdletSource.ps1
#>
[CmdletBinding()]
param(
    [string[]]$Class,
    [string]$OutRoot,
    [string]$DocsOut,
    [switch]$NoDocs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $OutRoot) { $OutRoot = Join-Path $repoRoot 'src' 'FogApi.Cmdlets' }
if (-not $DocsOut) { $DocsOut = Join-Path $repoRoot 'docs' 'commands' }

$specPath = Join-Path $repoRoot 'spec' 'fog-api-spec.json'
$spec = Get-Content -LiteralPath $specPath -Raw | ConvertFrom-Json

$modelDir  = Join-Path $OutRoot 'Models' 'Generated'
$cmdletDir = Join-Path $OutRoot 'Cmdlets' 'Generated'
foreach ($d in $modelDir, $cmdletDir) { $null = New-Item -ItemType Directory -Path $d -Force }
if (-not $NoDocs) { $null = New-Item -ItemType Directory -Path $DocsOut -Force }

# The assembly name, which is what PowerShell looks for a compiled cmdlet's MAML
# under: <ModuleBase>/<culture>/<AssemblyName>.dll-Help.xml. Not the module
# name -- the nested assembly is deliberately called something else, because a
# nested binary module sharing its parent's name makes Get-Module return two.
$helpFile = 'FogApi.Core.dll-Help.xml'

# --- helpers ---------------------------------------------------------------

# C# keywords are legal identifiers behind an @, and PowerShell never sees the
# @ -- a property written @default is a property named default. Six FOG fields
# need it: default, interface, params, protected, return.
$csKeywords = @(
    'abstract','as','base','bool','break','byte','case','catch','char','checked','class','const',
    'continue','decimal','default','delegate','do','double','else','enum','event','explicit','extern',
    'false','finally','fixed','float','for','foreach','goto','if','implicit','in','int','interface',
    'internal','is','lock','long','namespace','new','null','object','operator','out','override',
    'params','private','protected','public','readonly','ref','return','sbyte','sealed','short',
    'sizeof','stackalloc','static','string','struct','switch','this','throw','true','try','typeof',
    'uint','ulong','unchecked','unsafe','ushort','using','virtual','void','volatile','while')

function Get-CsIdentifier {
    param([string]$Name)
    if ($csKeywords -contains $Name) { return "@$Name" }
    return $Name
}

function Get-CsType {
    <#
    wireType is the resolved word an emitter acts on, so this is the only place
    that maps it. Every type is nullable: FOG answers an unset column with "" or
    a zero date, and a non-nullable field would turn "no value" into 0, false or
    01/01/0001 -- three different lies.
    #>
    param([string]$WireType)
    switch ($WireType) {
        'int'      { 'long?' }
        'number'   { 'double?' }
        'bool'     { 'bool?' }
        'bool01'   { 'bool?' }
        'dateTime' { 'DateTime?' }
        'date'     { 'DateTime?' }
        default    { 'string?' }
    }
}

function Get-ReaderCall {
    param([string]$WireType, [string]$Value)
    switch ($WireType) {
        'int'      { "FogRead.Int($Value)" }
        'number'   { "FogRead.Number($Value)" }
        'bool'     { "FogRead.Bool01($Value)" }
        'bool01'   { "FogRead.Bool01($Value)" }
        'dateTime' { "FogRead.DateTime($Value)" }
        'date'     { "FogRead.DateTime($Value)" }
        default    { "FogRead.String($Value)" }
    }
}

function Get-WireEnum {
    param([string]$WireType)
    switch ($WireType) {
        'int'      { 'FogWire.Int' }
        'number'   { 'FogWire.Number' }
        'bool'     { 'FogWire.Bool' }
        'bool01'   { 'FogWire.Bool01' }
        'dateTime' { 'FogWire.DateTime' }
        'date'     { 'FogWire.Date' }
        default    { 'FogWire.String' }
    }
}

function Get-TypeName {
    param([string]$SchemaName)
    "Fog$SchemaName"
}

function ConvertTo-CsString {
    param([string]$Value)
    if ($null -eq $Value) { return 'null' }
    '"' + ($Value -replace '\\', '\\' -replace '"', '\"') + '"'
}

function Format-XmlDoc {
    <#
    An XML doc comment cannot contain a raw &, < or >, and a stray */ inside one
    would close the surrounding block early -- the C# analogue of the trap the
    PowerShell emitter records about a close-comment marker inside a help block.
    #>
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    $t = $Text -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;'
    $t = $t -replace '\*/', '* /'
    ($t -replace '\s+', ' ').Trim()
}

$written = [System.Collections.Generic.List[string]]::new()

function Write-Emitted {
    param([string]$Path, [string]$Content)
    # utf8 with no BOM and no trailing newline juggling, so the drift test can
    # byte-compare what the emitter produces against what is on disk.
    Set-Content -LiteralPath $Path -Value $Content -Encoding utf8 -NoNewline
    $written.Add($Path)
}

# --- models ----------------------------------------------------------------

function New-ModelSource {
    param([string]$ClassName, $Schema)

    $type = Get-TypeName $Schema.schemaName
    $sb = [System.Collections.Generic.List[string]]::new()

    $sb.Add('// <auto-generated>')
    $sb.Add("//   Generated by spec/tools/New-FogCmdletSource.ps1 from schemas.$ClassName")
    $sb.Add("//   in spec/fog-api-spec.json. Edit the spec, not this file.")
    $sb.Add('// </auto-generated>')
    # Required, not decorative. Roslyn treats a file whose first comment says
    # auto-generated as OUTSIDE the nullable context, so every `string?` in it
    # is CS8669 -- "the annotation should only be used in code within a
    # #nullable annotations context" -- even with <Nullable>enable</Nullable>
    # set project-wide.
    $sb.Add('#nullable enable')
    $sb.Add('using System.Text.Json.Nodes;')
    $sb.Add('using System.Text.Json.Serialization;')
    $sb.Add('')
    $sb.Add('namespace FogApi.Models;')
    $sb.Add('')
    $sb.Add('/// <summary>')
    $sb.Add("/// A FOG $ClassName, from the <c>$($Schema.table)</c> table.")
    $sb.Add('/// </summary>')
    if (@($Schema.computed).Count -gt 0) {
        $sb.Add('/// <remarks>')
        $sb.Add('/// Responses may also carry fields that are not columns and are not declared')
        $sb.Add("/// here: $((@($Schema.computed) | ForEach-Object { $_ }) -join ', ').")
        $sb.Add('/// They arrive through <see cref="FogEntity"/>''s dynamic bag, so a caller')
        $sb.Add('/// reaches one by name without this type declaring it.')
        $sb.Add('/// </remarks>')
    }
    $sb.Add("[JsonConverter(typeof(FogEntityConverter<$type>))]")
    $sb.Add("public sealed class $type : FogEntity")
    $sb.Add('{')
    $sb.Add("    /// <summary>The fields FOG declares for a $ClassName.</summary>")
    $sb.Add('    public static readonly FogFieldMap FieldMap = new(')

    $fieldLines = foreach ($f in $Schema.fields) {
        $args = @(
            (ConvertTo-CsString $f.name)
            (ConvertTo-CsString $f.column)
            (Get-WireEnum $f.wireType)
        )
        if ($null -ne $f.maxLength) { $args += "MaxLength: $($f.maxLength)" }
        if ($f.readOnly) { $args += 'ReadOnly: true' }
        if ($f.writeOnly) { $args += 'WriteOnly: true' }
        "        new FogField($($args -join ', '))"
    }
    $sb.Add(($fieldLines -join ",`n") + ');')
    $sb.Add('')
    $sb.Add('    /// <inheritdoc/>')
    $sb.Add('    internal override FogFieldMap Map => FieldMap;')
    $sb.Add('')
    $sb.Add('    /// <inheritdoc/>')
    $sb.Add("    internal override string FogClass => $(ConvertTo-CsString $ClassName);")
    $sb.Add('')

    foreach ($f in $Schema.fields) {
        $csType = Get-CsType $f.wireType
        $ident = Get-CsIdentifier $f.name
        $backing = '_' + ($f.name -replace '[^A-Za-z0-9_]', '_')
        # Format-XmlDoc escapes < and >, so it runs on the raw column name and
        # the <c> wrapper goes on afterwards. Passing the whole string through
        # turned every doc comment into &lt;c&gt;pAlias&lt;/c&gt;.
        $doc = "<c>$(Format-XmlDoc $f.column)</c>"
        if ($null -ne $f.maxLength) { $doc += ", varchar($($f.maxLength))" }
        if ($f.readOnly) { $doc += '. Returned but not accepted' }
        if ($f.writeOnly) { $doc += '. Accepted but never returned' }
        $sb.Add("    private $csType $backing;")
        $sb.Add("    /// <summary>$doc.</summary>")
        $sb.Add("    public $csType $ident { get => $backing; set => Set(ref $backing, value); }")
        $sb.Add('')
    }

    $sb.Add('    /// <inheritdoc/>')
    $sb.Add('    public override object? ReadDeclared(string field) => field.ToLowerInvariant() switch')
    $sb.Add('    {')
    foreach ($f in $Schema.fields) {
        $sb.Add("        $(ConvertTo-CsString $f.name.ToLowerInvariant()) => $(Get-CsIdentifier $f.name),")
    }
    $sb.Add('        _ => null,')
    $sb.Add('    };')
    $sb.Add('')
    $sb.Add('    /// <inheritdoc/>')
    $sb.Add('    public override bool SetDeclared(string field, JsonNode? value)')
    $sb.Add('    {')
    $sb.Add('        switch (field.ToLowerInvariant())')
    $sb.Add('        {')
    foreach ($f in $Schema.fields) {
        $reader = Get-ReaderCall $f.wireType 'value'
        $sb.Add("            case $(ConvertTo-CsString $f.name.ToLowerInvariant()): $(Get-CsIdentifier $f.name) = $reader; return true;")
    }
    $sb.Add('            default: return false;')
    $sb.Add('        }')
    $sb.Add('    }')
    $sb.Add('}')

    ($sb -join "`n") + "`n"
}

# --- cmdlets ---------------------------------------------------------------

$baseByRoute = @{
    indiv  = 'FogGetCmdlet'
    list   = 'FogGetCmdlet'
    search = 'FogFindCmdlet'
    create = 'FogNewCmdlet'
    update = 'FogUpdateCmdlet'
    delete = 'FogRemoveCmdlet'
    task   = 'FogStartTaskCmdlet'
    cancel = 'FogStopTaskCmdlet'
    active = 'FogGetActiveCmdlet'
}

# Which shapes take a field parameter per writable column.
$takesFields = @('create', 'update')

function New-CmdletSource {
    param($Fn, $Schema)

    $verb, $noun = $Fn.functionName -split '-', 2
    $type = Get-TypeName $Schema.schemaName
    $base = $baseByRoute[$Fn.routeName]
    $className = ($Fn.functionName -replace '-', '') + 'Command'

    $sb = [System.Collections.Generic.List[string]]::new()
    $sb.Add('// <auto-generated>')
    $sb.Add("//   Generated by spec/tools/New-FogCmdletSource.ps1 from operation")
    $sb.Add("//   '$($Fn.operationId)' ($($Fn.method) $($Fn.path)) in spec/fog-api-spec.json.")
    $sb.Add('//   Edit the spec, not this file.')
    if ($Fn.permission) { $sb.Add("//   Requires the '$($Fn.permission)' permission.") }
    $sb.Add('// </auto-generated>')
    # See the model emitter: an auto-generated file is outside the nullable
    # context until it says otherwise.
    $sb.Add('#nullable enable')
    $sb.Add('using System.Management.Automation;')
    $sb.Add('using FogApi.Models;')
    $sb.Add('')
    $sb.Add('namespace FogApi.Cmdlets.Generated;')
    $sb.Add('')
    $sb.Add('/// <summary>')
    $sb.Add("/// $(Format-XmlDoc $Fn.summary).")
    $sb.Add('/// </summary>')

    $verbConst = Get-VerbConstant $verb
    $attrArgs = @($verbConst, (ConvertTo-CsString $noun))
    if ($Fn.routeName -in @('create', 'update', 'delete', 'task', 'cancel')) {
        $attrArgs += 'SupportsShouldProcess = true'
    }
    $sb.Add("[Cmdlet($($attrArgs -join ', '))]")
    # Filtered, because @($null).Count is 1 and an unfiltered wrap emits
    # [Alias("")] on every cmdlet that has no alias.
    $cmdletAliases = @($Fn.aliases | Where-Object { $_ })
    if ($cmdletAliases.Count -gt 0) {
        $quoted = ($cmdletAliases | ForEach-Object { ConvertTo-CsString $_ }) -join ', '
        $sb.Add("[Alias($quoted)]")
    }
    $sb.Add("[OutputType(typeof($type))]")
    $sb.Add("public sealed class $className : $base<$type>")
    $sb.Add('{')
    $sb.Add('    /// <inheritdoc/>')
    $sb.Add("    protected override string FogClass => $(ConvertTo-CsString $Fn.class);")

    if ($Fn.routeName -in $takesFields) {
        $mandatory = $Fn.routeName -eq 'create'
        foreach ($f in $Schema.fields) {
            if ($f.readOnly) { continue }
            $sb.Add('')
            # Format-XmlDoc escapes < and >, so it runs on the raw column name and
            # the <c> wrapper goes on afterwards. Passing the whole string
            # through turned every doc comment into &lt;c&gt;pAlias&lt;/c&gt;.
            $doc = "<c>$(Format-XmlDoc $f.column)</c>"
            if ($f.writeOnly) { $doc += '. Never returned by the API' }
            $sb.Add("    /// <summary>$doc.</summary>")
            $attr = if ($mandatory -and $f.required) { '[Parameter(Mandatory = true)]' } else { '[Parameter]' }
            $sb.Add("    $attr")
            foreach ($v in (Get-ValidationAttributes $f)) { $sb.Add("    $v") }
            $fieldAliases = @($f.aliases | Where-Object { $_ })
            if ($fieldAliases.Count -gt 0) {
                $quoted = ($fieldAliases | ForEach-Object { ConvertTo-CsString $_ }) -join ', '
                $sb.Add("    [Alias($quoted)]")
            }
            $sb.Add("    public $(Get-CsType $f.wireType) $(Get-CsIdentifier $f.name) { get; set; }")
        }
    }

    $sb.Add('}')
    ($sb -join "`n") + "`n"
}

function Get-VerbConstant {
    <#
    The System.Management.Automation.Verbs* constant for an approved verb, so
    the generated attribute reads [Cmdlet(VerbsCommon.Get, "FogPrinter")] rather
    than a bare string. A typo in a literal would only surface as a
    PSUseApprovedVerbs warning; a wrong constant name does not compile.
    #>
    param([string]$Verb)
    $map = @{
        Get = 'VerbsCommon.Get'; New = 'VerbsCommon.New'; Remove = 'VerbsCommon.Remove'
        Set = 'VerbsCommon.Set'; Add = 'VerbsCommon.Add'; Clear = 'VerbsCommon.Clear'
        Find = 'VerbsCommon.Find'; Rename = 'VerbsCommon.Rename'; Copy = 'VerbsCommon.Copy'
        Move = 'VerbsCommon.Move'; Join = 'VerbsCommon.Join'; Search = 'VerbsCommon.Search'
        Update = 'VerbsData.Update'; Export = 'VerbsData.Export'; Import = 'VerbsData.Import'
        Sync = 'VerbsData.Sync'; Restore = 'VerbsData.Restore'; Backup = 'VerbsData.Backup'
        Start = 'VerbsLifecycle.Start'; Stop = 'VerbsLifecycle.Stop'; Restart = 'VerbsLifecycle.Restart'
        Invoke = 'VerbsLifecycle.Invoke'; Enable = 'VerbsLifecycle.Enable'; Disable = 'VerbsLifecycle.Disable'
        Approve = 'VerbsLifecycle.Approve'; Deny = 'VerbsLifecycle.Deny'; Register = 'VerbsLifecycle.Register'
        Unregister = 'VerbsLifecycle.Unregister'; Wait = 'VerbsLifecycle.Wait'; Install = 'VerbsLifecycle.Install'
        Uninstall = 'VerbsLifecycle.Uninstall'; Resume = 'VerbsLifecycle.Resume'; Suspend = 'VerbsLifecycle.Suspend'
        Test = 'VerbsDiagnostic.Test'; Measure = 'VerbsDiagnostic.Measure'; Repair = 'VerbsDiagnostic.Repair'
        Resolve = 'VerbsDiagnostic.Resolve'; Debug = 'VerbsDiagnostic.Debug'; Ping = 'VerbsDiagnostic.Ping'
        Trace = 'VerbsDiagnostic.Trace'; Connect = 'VerbsCommunications.Connect'
        Disconnect = 'VerbsCommunications.Disconnect'; Read = 'VerbsCommunications.Read'
        Receive = 'VerbsCommunications.Receive'; Send = 'VerbsCommunications.Send'
        Write = 'VerbsCommunications.Write'; Mount = 'VerbsData.Mount'; Dismount = 'VerbsData.Dismount'
    }
    if (-not $map.ContainsKey($Verb)) {
        throw "no Verbs* constant known for '$Verb'. Add it to Get-VerbConstant, or the spec has an unapproved verb the builder should have refused."
    }
    $map[$Verb]
}

function Get-ValidationAttributes {
    <#
    Mutually exclusive, in this order, and the exclusivity is deliberate: two
    attributes saying overlapping things produce two different error messages
    for the same mistake. The PowerShell emitter records the same rule.
    #>
    param($Field)
    $out = @()
    # @($null).Count is 1, not 0. Testing the wrapped array directly put
    # [ValidateSet("")] on all 431 fields and stopped maxLength ever being
    # reached, because the enum branch always won.
    $enumValues = @($Field.enum | Where-Object { $null -ne $_ })

    if ($enumValues.Count -gt 0) {
        # A 0/1 column is a bool to the caller, so a ValidateSet of "0","1"
        # would reject $true. The wire conversion already constrains it.
        if ($Field.wireType -ne 'bool01') {
            $quoted = ($enumValues | ForEach-Object { ConvertTo-CsString ([string]$_) }) -join ', '
            $out += "[ValidateSet($quoted)]"
        }
    }
    elseif ($Field.pattern) {
        $out += "[ValidatePattern($(ConvertTo-CsString $Field.pattern))]"
    }
    elseif ($null -ne $Field.maxLength -and $Field.wireType -eq 'string') {
        # Not a number anyone typed: it is the column's varchar length, read
        # through the document.
        $out += "[ValidateLength(0, $($Field.maxLength))]"
    }
    $out
}

# --- run -------------------------------------------------------------------

$candidates = @($spec.functions | Where-Object { $_.status -in @('generate', 'replaces-thin-wrapper') })
if ($Class) { $candidates = @($candidates | Where-Object { $_.class -in $Class }) }

$schemaClasses = @($spec.schemas.PSObject.Properties.Name)
if ($Class) { $schemaClasses = @($schemaClasses | Where-Object { $_ -in $Class }) }

$modelCount = 0
foreach ($className in $schemaClasses) {
    $schema = $spec.schemas.$className
    $type = Get-TypeName $schema.schemaName
    Write-Emitted (Join-Path $modelDir "$type.cs") (New-ModelSource -ClassName $className -Schema $schema)
    $modelCount++
}

$cmdletCount = 0
$skipped = [System.Collections.Generic.List[string]]::new()
foreach ($fn in $candidates) {
    if (-not $baseByRoute.ContainsKey($fn.routeName)) {
        $skipped.Add("$($fn.functionName) (no base class for route '$($fn.routeName)')")
        continue
    }
    if (-not $fn.schema -or -not $spec.schemas.PSObject.Properties.Name.Contains($fn.class)) {
        $skipped.Add("$($fn.functionName) (no schema for class '$($fn.class)')")
        continue
    }
    $schema = $spec.schemas.($fn.class)
    $className = ($fn.functionName -replace '-', '') + 'Command'
    Write-Emitted (Join-Path $cmdletDir "$className.cs") (New-CmdletSource -Fn $fn -Schema $schema)
    $cmdletCount++
}

Write-Host ("wrote {0} model(s) to {1}" -f $modelCount, $modelDir)
Write-Host ("wrote {0} cmdlet(s) to {1}" -f $cmdletCount, $cmdletDir)
if ($skipped.Count -gt 0) {
    # Never silent. A cmdlet the spec specifies and the emitter did not write is
    # a coverage hole, and a hole nobody is told about is the one that ships.
    Write-Warning "skipped $($skipped.Count):"
    $skipped | ForEach-Object { Write-Warning "  $_" }
}
