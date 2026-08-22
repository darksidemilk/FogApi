#Requires -Version 5.1
<#
.SYNOPSIS
Emits FogApi cmdlet files from spec/fog-api-spec.json.

.DESCRIPTION
The PowerShell emitter. It reads the resolved spec and nothing else -- no
OpenAPI document, no overlay, no naming rules of its own -- which is what makes
a Python or bash emitter a sibling of this file rather than a rewrite of it.

Six shapes are emitted, one per generic route: list, indiv, create, update,
delete and search. Everything an emitted file needs comes from the spec: the
verb, the noun, the L1 function to call, the core object name, the typed fields
with their lengths and enums, and whether FOG 1.5 serves the operation and under
which route spelling.

Constraints the build scripts impose on the output, each learned the hard way:

  - Exactly one comment-based help block per file, and it must come first. Both
    build scripts find the block by searching for the opening and closing
    markers with IndexOf -- first occurrence only -- so a second block
    truncates the file. Note that this applies to this script too: a literal
    close-comment marker written inside a help block ends the block there, and
    the rest of the prose is then parsed as code.
  - The Alias attribute goes on the line immediately after CmdletBinding.
    Get-AliasesToExport indexes that exact line and silently drops an alias
    declared anywhere else.
  - Files go flat in Public/. FogApi.psm1 globs Public/*.ps1 without -Recurse,
    so a Generated/ subfolder would be skipped at import with no error.
  - Every example carries an "Expected output:" block, because
    Tests/FogApi.Examples.Tests.ps1 runs the examples and asserts against it.
    An example without one is an untested example.

.PARAMETER Class
Emit only the operations for these route classes. Omit for all of them.

.PARAMETER SpecFile
Path to the resolved spec. Defaults to spec/fog-api-spec.json.

.PARAMETER OutDir
Where to write. Defaults to FogApi/Public.

.PARAMETER WhatIfOnly
List what would be written without writing anything.

.EXAMPLE
./spec/tools/New-FogApiFunctionFile.ps1 -Class printer

Emits the six printer cmdlets.

.EXAMPLE
./spec/tools/New-FogApiFunctionFile.ps1 -WhatIfOnly

Lists every file the emitter would write, with the operation each comes from.
#>
[CmdletBinding()]
param (
    [string[]]$Class,
    [string]$SpecFile,
    [string]$OutDir,
    [switch]$WhatIfOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$specRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$repoRoot = Split-Path -Parent $specRoot
if (-not $SpecFile) { $SpecFile = Join-Path $specRoot 'fog-api-spec.json' }
if (-not $OutDir)   { $OutDir   = Join-Path (Join-Path $repoRoot 'FogApi') 'Public' }

if (-not (Test-Path -LiteralPath $SpecFile)) {
    throw "Spec not found at $SpecFile. Run spec/tools/Build-FogApiSpec.ps1 first."
}
$spec = Get-Content -LiteralPath $SpecFile -Raw | ConvertFrom-Json

$targets = @($spec.functions | Where-Object { $_.status -in @('generate', 'replaces-thin-wrapper') })
if ($Class) { $targets = @($targets | Where-Object { $_.class -in $Class }) }
if (-not $targets) { throw 'no operations matched' }

function Get-FieldList {
    param([string]$ClassName)
    if (-not ($spec.schemas.PSObject.Properties.Name -contains $ClassName)) { return @() }
    @($spec.schemas.$ClassName.fields)
}

function Get-SampleValue {
    <#
    A plausible value for a field, used only in generated help examples. Derived
    from the field's own type and length so an example never shows a value the
    server would reject.
    #>
    param($Field)
    switch ($Field.type) {
        'integer' { '1' }
        'number'  { '1' }
        'boolean' { '$true' }
        default   {
            if ($Field.enum) { "'{0}'" -f $Field.enum[0] }
            elseif ($Field.name -eq 'name') { "'ExamplePrinter'" }
            else { "'example'" }
        }
    }
}

function Format-HelpParam {
    param([string]$Name, [string]$Text)
    @(('    .PARAMETER {0}' -f $Name), ('    {0}' -f $Text), '')
}

function New-FieldParamBlock {
    <#
    Typed parameters, one per writable field, so an admin tab-completes instead
    of guessing at JSON. maxLength and enum come straight from the server's own
    column definition, which is the whole reason for generating from the spec
    rather than by hand -- these would otherwise be transcribed and go stale.
    #>
    param($Fields, [switch]$RequiredAsMandatory)
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($f in $Fields) {
        if ($f.readOnly) { continue }
        $attrs = [System.Collections.Generic.List[string]]::new()
        if ($RequiredAsMandatory -and $f.required) {
            $attrs.Add('        [Parameter(Mandatory=$true)]')
        } else {
            $attrs.Add('        [Parameter()]')
        }
        if ($f.enum) {
            $set = (@($f.enum) | ForEach-Object { "'$_'" }) -join ','
            $attrs.Add("        [ValidateSet($set)]")
        } elseif ($f.maxLength) {
            $attrs.Add("        [ValidateLength(0,$($f.maxLength))]")
        }
        $type = switch ($f.type) { 'integer' { '[int]' } 'number' { '[double]' } 'boolean' { '[bool]' } default { '[string]' } }
        $attrs.Add(('        {0}${1},' -f $type, $f.name))
        foreach ($a in $attrs) { $lines.Add($a) }
    }
    if ($lines.Count -gt 0) {
        $lines[$lines.Count - 1] = $lines[$lines.Count - 1].TrimEnd(',')
    }
    $lines
}

function New-PayloadBlock {
    <#
    Only the parameters the caller actually bound go into the payload. FOG's
    edit route merges, so sending an unbound parameter as an empty string
    overwrites a real value with nothing -- a data-loss bug, not a cosmetic one.

    The accumulator is $payload rather than $settings because -settings is a
    parameter on the same function; reusing the name would have the merge loop
    read and write the same variable.
    #>
    param($Fields)
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('        $payload = @{};')
    foreach ($f in $Fields) {
        if ($f.readOnly) { continue }
        $lines.Add(('        if ($PSBoundParameters.ContainsKey(''{0}'')) {{ $payload.{0} = ${0}; }}' -f $f.name))
    }
    $lines.Add('        # -settings wins, so a caller can reach a field this module does not')
    $lines.Add('        # model yet without the named parameters fighting them for it.')
    $lines.Add('        if ($PSBoundParameters.ContainsKey(''settings'')) {')
    $lines.Add('            foreach ($key in $settings.Keys) { $payload[$key] = $settings[$key]; }')
    $lines.Add('        }')
    $lines
}

function New-GeneratedNote {
    param($Fn)
    @(
        '    .NOTES',
        ('    Generated by spec/tools/New-FogApiFunctionFile.ps1 from operation ''{0}''' -f $Fn.operationId),
        ('    ({1} {2}) in spec/fog-api-spec.json. Edit the spec, not this file.' -f $null, $Fn.method, $Fn.path),
        $(if ($Fn.permission) { '    Requires the ''{0}'' permission.' -f $Fn.permission } else { $null }),
        $(if (-not $Fn.onFogFifteen) { '    FOG 1.6 only; FOG 1.5 does not serve this operation.' } else { $null })
    ) | Where-Object { $null -ne $_ }
}

function New-FunctionFile {
    param($Fn)

    $noun = $Fn.class
    $fields = Get-FieldList $noun
    $writable = @($fields | Where-Object { -not $_.readOnly })
    $nameField = @($fields | Where-Object { $_.name -eq 'name' })[0]
    $aliasLine = if ($Fn.aliases -and $Fn.aliases.Count -gt 0) {
        "    [Alias('{0}')]" -f ($Fn.aliases -join "','")
    } else { $null }

    $body = [System.Collections.Generic.List[string]]::new()
    $help = [System.Collections.Generic.List[string]]::new()
    $params = [System.Collections.Generic.List[string]]::new()

    switch ($Fn.routeName) {
        'list' {
            $help.Add('    .SYNOPSIS')
            $help.Add(('    Gets every {0} on the fog server.' -f $noun))
            $help.Add('')
            $help.Add('    .DESCRIPTION')
            $help.Add(('    Returns all {0} objects. On FOG 1.6 the list is paged automatically and' -f $noun))
            $help.Add('    every page is followed, so the result is complete rather than capped at the')
            $help.Add(('    server''s row limit ({0} rows). Filter the result with Where-Object.' -f $spec.paging.maxRows))
            $help.Add('')
            $help.AddRange([string[]]@(Format-HelpParam 'First' 'Return at most this many objects.'))
            $help.AddRange([string[]]@(Format-HelpParam 'Skip' 'Skip this many objects before returning any.'))
            $help.AddRange([string[]]@(Format-HelpParam 'PageSize' 'Rows to request per page. Ignored on FOG 1.5, which does not page.'))
            $help.AddRange([string[]]@(Format-HelpParam 'NoAutoPage' 'Return only the first page instead of following nextUrl.'))
            $help.Add('    .EXAMPLE')
            $help.Add(('    {0}' -f $Fn.functionName))
            $help.Add('')
            $help.Add(('    Returns an array of every {0}.' -f $noun))
            $help.Add('')
            $help.Add('    Expected output:')
            $help.Add(('    [ {{ "id": 1, "name": "Example{0}" }} ]' -f (Get-Culture).TextInfo.ToTitleCase($noun)))
            $help.Add('')
            $params.Add('        [Parameter()]')
            $params.Add('        [int]$First,')
            $params.Add('        [Parameter()]')
            $params.Add('        [int]$Skip,')
            $params.Add('        [Parameter()]')
            $params.Add('        [int]$PageSize = 1000,')
            $params.Add('        [Parameter()]')
            $params.Add('        [switch]$NoAutoPage')
            $body.Add(('        Write-Verbose "getting all fog {0} objects";' -f $noun))
            $body.Add('        $splat = @{ type = ''object''; coreObject = ''' + $noun + ''' };')
            $body.Add('        foreach ($p in @(''First'',''Skip'',''PageSize'',''NoAutoPage'')) {')
            $body.Add('            if ($PSBoundParameters.ContainsKey($p)) { $splat[$p] = $PSBoundParameters[$p]; }')
            $body.Add('        }')
            $body.Add('        return (Get-FogObject @splat).data;')
        }
        'indiv' {
            $help.Add('    .SYNOPSIS')
            $help.Add(('    Gets one {0} by id.' -f $noun))
            $help.Add('')
            $help.Add('    .DESCRIPTION')
            $help.Add(('    Returns a single {0} object. Fields the list route withholds are returned' -f $noun))
            $help.Add('    here, which is the reason to fetch by id rather than filter a list.')
            $help.Add('')
            $help.AddRange([string[]]@(Format-HelpParam 'id' ('The id of the {0} to get. Accepts an id or an object with an id property, and binds from the pipeline.' -f $noun)))
            $help.Add('    .EXAMPLE')
            $help.Add(('    {0} -id 1' -f $Fn.functionName))
            $help.Add('')
            $help.Add(('    Returns the {0} with id 1.' -f $noun))
            $help.Add('')
            $help.Add('    Expected output:')
            $help.Add(('    {{ "id": 1, "name": "Example{0}" }}' -f (Get-Culture).TextInfo.ToTitleCase($noun)))
            $help.Add('')
            $params.Add('        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]')
            $params.Add('        [Alias(''IDofObject'')]')
            $params.Add('        [Object]$id')
            $body.Add('        # An id, or an object carrying one. Every generated cmdlet accepts both,')
            $body.Add('        # so a result from one can be piped straight into another.')
            $body.Add('        $objectId = if ($id -is [System.Management.Automation.PSObject] -and $id.PSObject.Properties.Name -contains ''id'') { $id.id } else { $id };')
            $body.Add(('        Write-Verbose "getting fog {0} $objectId";' -f $noun))
            $body.Add('        # No .data here. Get-FogObject only runs its result through')
            $body.Add('        # Add-FogResultData when no id was given, because a fetch by id returns the')
            $body.Add('        # bare object rather than a list envelope. Taking .data returns $null.')
            $body.Add(('        return Get-FogObject -type object -coreObject {0} -IDofObject $objectId;' -f $noun))
        }
        'search' {
            $help.Add('    .SYNOPSIS')
            $help.Add(('    Finds {0} objects matching a search term.' -f $noun))
            $help.Add('')
            $help.Add('    .DESCRIPTION')
            $help.Add(('    Matches the term across the {0} class fields and returns the same envelope' -f $noun))
            $help.Add('    a list does.')
            $help.Add('')
            $help.AddRange([string[]]@(Format-HelpParam 'stringToSearch' 'Text to match across the class fields.'))
            $help.Add('    .EXAMPLE')
            $help.Add(('    {0} -stringToSearch ''Example''' -f $Fn.functionName))
            $help.Add('')
            $help.Add(('    Returns every {0} matching "Example".' -f $noun))
            $help.Add('')
            $help.Add('    Expected output:')
            $help.Add(('    [ {{ "id": 1, "name": "Example{0}" }} ]' -f (Get-Culture).TextInfo.ToTitleCase($noun)))
            $help.Add('')
            $params.Add('        [Parameter(Mandatory=$true,Position=0)]')
            $params.Add('        [string]$stringToSearch')
            $body.Add(('        Write-Verbose "searching fog {0} for $stringToSearch";' -f $noun))
            $body.Add('        # -type search is passed explicitly even though it is that parameter''s')
            $body.Add('        # default. A DynamicParam block sees only bound parameters, so with -type')
            $body.Add('        # left off, Set-DynamicParams is handed $null, adds no -coreObject, and the')
            $body.Add('        # call fails to bind.')
            $body.Add(('        return (Find-FogObject -type search -coreObject {0} -stringToSearch $stringToSearch).data;' -f $noun))
        }
        'create' {
            $help.Add('    .SYNOPSIS')
            $help.Add(('    Creates a {0}.' -f $noun))
            $help.Add('')
            $help.Add('    .DESCRIPTION')
            $help.Add(('    Creates a new {0} object. Every writable field of the class is a named' -f $noun))
            $help.Add('    parameter, with the length and value constraints the server itself declares.')
            $help.Add('    Use -settings for a field a newer server has added that this module does not')
            $help.Add('    yet know about.')
            $help.Add('')
            foreach ($f in $writable) {
                $req = if ($f.required) { ' Required.' } else { '' }
                $len = if ($f.maxLength) { " At most $($f.maxLength) characters." } else { '' }
                $help.AddRange([string[]]@(Format-HelpParam $f.name ("Sets the {0} field (column {1})."-f $f.name, $f.column) + $req + $len))
            }
            $help.AddRange([string[]]@(Format-HelpParam 'settings' 'A hashtable of raw field values, merged over the named parameters. An escape hatch for fields not yet modelled.'))
            $help.Add('    .EXAMPLE')
            $sample = if ($nameField) { ('{0} -name {1}' -f $Fn.functionName, (Get-SampleValue $nameField)) } else { $Fn.functionName }
            $help.Add(('    {0}' -f $sample))
            $help.Add('')
            $help.Add(('    Creates a {0} and returns the created object.' -f $noun))
            $help.Add('')
            $help.Add('    Expected output:')
            $help.Add(('    {{ "id": 1, "name": "Example{0}" }}' -f (Get-Culture).TextInfo.ToTitleCase($noun)))
            $help.Add('')
            $params.AddRange([string[]]@(New-FieldParamBlock -Fields $writable -RequiredAsMandatory))
            $params[$params.Count - 1] = $params[$params.Count - 1] + ','
            $params.Add('        [Parameter()]')
            $params.Add('        [hashtable]$settings')
            $body.AddRange([string[]]@(New-PayloadBlock -Fields $writable))
            $body.Add(('        Write-Verbose "creating fog {0}";' -f $noun))
            $body.Add(('        return New-FogObject -type object -coreObject {0} -jsonData ($payload | ConvertTo-Json -Compress);' -f $noun))
        }
        'update' {
            $help.Add('    .SYNOPSIS')
            $help.Add(('    Updates a {0}.' -f $noun))
            $help.Add('')
            $help.Add('    .DESCRIPTION')
            $help.Add(('    Sends only the fields you name. FOG merges an edit into the existing row, so' -f $noun))
            $help.Add('    an unbound parameter is left alone rather than blanked -- which is why this')
            $help.Add('    builds its payload from $PSBoundParameters rather than from every parameter.')
            $help.Add('')
            $help.AddRange([string[]]@(Format-HelpParam 'id' ('The id of the {0} to update. Accepts an id or an object with an id property, and binds from the pipeline.' -f $noun)))
            foreach ($f in $writable) {
                $len = if ($f.maxLength) { " At most $($f.maxLength) characters." } else { '' }
                $help.AddRange([string[]]@(Format-HelpParam $f.name (("Sets the {0} field (column {1})." -f $f.name, $f.column) + $len)))
            }
            $help.AddRange([string[]]@(Format-HelpParam 'settings' 'A hashtable of raw field values, merged over the named parameters.'))
            $help.Add('    .EXAMPLE')
            $help.Add(('    {0} -id 1 -description ''Updated''' -f $Fn.functionName))
            $help.Add('')
            $help.Add(('    Updates the description of {0} 1.' -f $noun))
            $help.Add('')
            $help.Add('    Expected output:')
            $help.Add('    { "id": 1, "description": "Updated" }')
            $help.Add('')
            $params.Add('        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]')
            $params.Add('        [Alias(''IDofObject'')]')
            $params.Add('        [Object]$id,')
            $params.AddRange([string[]]@(New-FieldParamBlock -Fields $writable))
            $params[$params.Count - 1] = $params[$params.Count - 1] + ','
            $params.Add('        [Parameter()]')
            $params.Add('        [hashtable]$settings')
            $body.Add('        $objectId = if ($id -is [System.Management.Automation.PSObject] -and $id.PSObject.Properties.Name -contains ''id'') { $id.id } else { $id };')
            $body.AddRange([string[]]@(New-PayloadBlock -Fields $writable))
            $body.Add(('        Write-Verbose "updating fog {0} $objectId";' -f $noun))
            $body.Add(('        return Update-FogObject -type object -coreObject {0} -IDofObject $objectId -jsonData ($payload | ConvertTo-Json -Compress);' -f $noun))
        }
        'delete' {
            $help.Add('    .SYNOPSIS')
            $help.Add(('    Removes a {0}.' -f $noun))
            $help.Add('')
            $help.Add('    .DESCRIPTION')
            $help.Add(('    Deletes the {0} with the given id. The row is gone; FOG has no undo for this.' -f $noun))
            $help.Add('')
            $help.AddRange([string[]]@(Format-HelpParam 'id' ('The id of the {0} to remove. Accepts an id or an object with an id property, and binds from the pipeline.' -f $noun)))
            $help.Add('    .EXAMPLE')
            $help.Add(('    {0} -id 1' -f $Fn.functionName))
            $help.Add('')
            $help.Add(('    Removes {0} 1.' -f $noun))
            $help.Add('')
            $help.Add('    Expected output:')
            $help.Add('    ""')
            $help.Add('')
            $params.Add('        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]')
            $params.Add('        [Alias(''IDofObject'')]')
            $params.Add('        [Object]$id')
            $body.Add('        $objectId = if ($id -is [System.Management.Automation.PSObject] -and $id.PSObject.Properties.Name -contains ''id'') { $id.id } else { $id };')
            $body.Add(('        Write-Verbose "removing fog {0} $objectId";' -f $noun))
            $body.Add(('        return Remove-FogObject -type object -coreObject {0} -IDofObject $objectId;' -f $noun))
        }
        default { throw "no template for route '$($Fn.routeName)'" }
    }

    $help.AddRange([string[]]@(New-GeneratedNote $Fn))

    $out = [System.Collections.Generic.List[string]]::new()
    $out.Add(('function {0} {{' -f $Fn.functionName))
    $out.Add('    <#')
    foreach ($l in $help) { $out.Add($l) }
    $out.Add('    #>')
    $out.Add('')
    $out.Add('    [CmdletBinding()]')
    if ($aliasLine) { $out.Add($aliasLine) }
    $out.Add('    param (')
    foreach ($l in $params) { $out.Add($l) }
    $out.Add('    )')
    $out.Add('')
    $out.Add('    process {')
    foreach ($l in $body) { $out.Add($l) }
    $out.Add('    }')
    $out.Add('')
    $out.Add('}')
    ($out -join [Environment]::NewLine) + [Environment]::NewLine
}

$written = 0
foreach ($fn in ($targets | Sort-Object functionName)) {
    $path = Join-Path $OutDir ("{0}.ps1" -f $fn.functionName)
    if ($WhatIfOnly) {
        Write-Host ("would write {0,-38} <- {1}" -f $fn.functionName, $fn.operationId)
        continue
    }
    $content = New-FunctionFile $fn
    Set-Content -LiteralPath $path -Value $content -Encoding utf8 -NoNewline
    Write-Host ("wrote {0,-38} <- {1}" -f $fn.functionName, $fn.operationId)
    $written++
}
if (-not $WhatIfOnly) { Write-Host "$written file(s) written to $OutDir" }
