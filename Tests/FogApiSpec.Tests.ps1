#
# The spec pipeline's own tests.
#
# Generated code is only trustworthy if it provably came from the spec. Three
# things can silently break that, and each gets a test:
#
#   1. The resolved spec is stale -- someone changed an input and did not
#      rebuild, so the coverage matrix and the emitters disagree with the
#      snapshot.
#   2. A generated file was hand-edited. The edit survives until the next
#      emitter run, then vanishes without trace, and the reason it vanished is
#      not obvious to whoever lost the change.
#   3. The manifest drifted from the files on disk. This has already happened
#      twice in this repo.
#
# All three are cheap to check by regenerating into a temp directory and
# comparing. Nothing here touches the network.
#
BeforeDiscovery {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:SpecRoot = Join-Path $script:RepoRoot 'spec'
    $script:SpecFile = Join-Path $script:SpecRoot 'fog-api-spec.json'
    $script:HasSpec = Test-Path -LiteralPath $script:SpecFile
}

Describe 'FOG API spec pipeline' -Skip:(-not $script:HasSpec) {

    BeforeAll {
        $script:RepoRoot = Split-Path -Parent $PSScriptRoot
        $script:SpecRoot = Join-Path $script:RepoRoot 'spec'
        $script:SpecFile = Join-Path $script:SpecRoot 'fog-api-spec.json'
        $script:Spec = Get-Content -LiteralPath $script:SpecFile -Raw | ConvertFrom-Json
        $script:Snapshot = Get-Content -LiteralPath (Join-Path $script:SpecRoot 'openapi/fog-1.6.json') -Raw | ConvertFrom-Json
        $script:Scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("fogapi-spec-" + [guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $script:Scratch -Force
    }

    AfterAll {
        if ($script:Scratch -and (Test-Path -LiteralPath $script:Scratch)) {
            Remove-Item -LiteralPath $script:Scratch -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'the snapshot' {
        It 'is the document FOG 1.6 serves, not a hand-written approximation' {
            # These are the shapes every emitter reads. If the generator upstream
            # stops emitting them, generated cmdlets lose their typed parameters
            # and nobody would otherwise notice until the output looked thin.
            $script:Snapshot.openapi | Should -Be '3.0.3'
            $script:Snapshot.'x-fog-paging'.maxRows | Should -BeGreaterThan 0
            $script:Snapshot.components.schemas.Printer.properties.name.'x-fog-column' | Should -Be 'pAlias'
            $script:Snapshot.paths.'/printer'.get.operationId | Should -Be 'listPrinter'
        }

        It 'has a provenance record naming the commit it came from' {
            $provenance = Get-Content -LiteralPath (Join-Path $script:SpecRoot 'openapi/PROVENANCE.json') -Raw | ConvertFrom-Json
            $provenance.source.commit | Should -Match '^[0-9a-f]{40}$'
            $provenance.source.fogVersion | Should -Be $script:Snapshot.info.version
        }
    }

    Context 'the resolved spec' {
        It 'is up to date with its inputs' {
            $rebuilt = Join-Path $script:Scratch 'fog-api-spec.json'
            & (Join-Path $script:SpecRoot 'tools/Build-FogApiSpec.ps1') -OutFile $rebuilt | Out-Null
            $expected = (Get-Content -LiteralPath $rebuilt -Raw).Trim()
            $actual = (Get-Content -LiteralPath $script:SpecFile -Raw).Trim()
            $actual | Should -Be $expected -Because 'spec/fog-api-spec.json is stale. Run spec/tools/Build-FogApiSpec.ps1.'
        }

        It 'uses only approved PowerShell verbs' {
            $approved = @(Get-Verb | ForEach-Object { $_.Verb })
            $names = @($script:Spec.functions | ForEach-Object { $_.functionName }) +
                     @($script:Spec.fixedRoutes | ForEach-Object { $_.functionName })
            foreach ($name in $names) {
                $verb = $name.Split('-')[0]
                $approved | Should -Contain $verb -Because "$name would fail PSUseApprovedVerbs"
            }
        }

        It 'routes every generated cmdlet through the L1 layer' {
            # Only the tier-5 fixed routes may call Invoke-FogApi directly, and
            # only because those endpoints have no L1 representation at all.
            foreach ($fn in $script:Spec.functions) {
                $fn.l1Function | Should -Not -BeNullOrEmpty -Because "$($fn.functionName) has no L1 function"
            }
        }

        It 'resolves a wireType for every field' {
            # Total by construction, and worth pinning: an unresolved field
            # would reach an emitter with nothing to act on, and the emitter
            # would fall back to string. A date silently becoming a string is
            # the exact defect the format passthrough was added to fix.
            $fields = @($script:Spec.schemas.PSObject.Properties.Value.fields)
            $fields.Count | Should -BeGreaterThan 400
            $known = @('string', 'int', 'number', 'bool', 'bool01', 'dateTime', 'date')
            foreach ($f in $fields) {
                $f.wireType | Should -BeIn $known -Because "field '$($f.name)' resolved to an unknown wireType"
            }
            @($fields | Where-Object { $_.wireType -eq 'bool01' }).Count |
                Should -BeGreaterThan 20 -Because 'FOG spells booleans enum(0,1); losing them means every boolean became a bare string'
            @($fields | Where-Object { $_.wireType -eq 'dateTime' }).Count |
                Should -BeGreaterThan 10 -Because 'the OpenAPI format is what carries these; a builder that stops reading it drops them silently'
        }

        It 'still finds the computed fields FOG names in prose' {
            # These are parsed out of an English sentence, because FOG names
            # them nowhere else. So the way this breaks is upstream rewording
            # the sentence: the parse then yields nothing, no error is raised,
            # and 80 fields quietly stop being modelled. A floor is the only
            # thing that would notice.
            $script:Spec.stats.computedFields |
                Should -BeGreaterThan 60 -Because 'the description sentence _entitySchema() writes has probably been reworded upstream; re-check Resolve-ComputedFields'
            @($script:Spec.schemas.host.computed) |
                Should -Contain 'mac' -Because 'host is the class with the most computed fields and the one most likely to be noticed'
        }

        It 'never lists a computed field that is also a declared one' {
            # plugin.description is both -- a real column the model overwrites
            # from the plugin's own metadata. Emitting both would be a
            # duplicate member, which in C# is a compile error.
            foreach ($c in $script:Spec.schemas.PSObject.Properties) {
                $declared = @($c.Value.fields.name)
                foreach ($n in @($c.Value.computed)) {
                    $declared | Should -Not -Contain $n -Because "$($c.Name).$n is declared and computed; the declared one wins"
                }
            }
        }
    }

    Context 'the emitted C# files' {
        # The generated surface is C# now, so this is what the drift gate has
        # to compare. A hand edit to a generated .cs survives exactly until the
        # next emitter run, then vanishes without trace -- the same failure the
        # .ps1 version of this test was written for.
        It 'match what the C# emitter produces right now' {
            & (Join-Path $script:SpecRoot 'tools/New-FogCmdletSource.ps1') `
                -Class printer -OutRoot $script:Scratch -NoDocs | Out-Null

            $emitted = @(Get-ChildItem -LiteralPath $script:Scratch -Filter '*.cs' -Recurse)
            $emitted.Count | Should -BeGreaterThan 0 -Because 'the emitter should have written the printer model and its cmdlets'

            $realRoot = Join-Path $script:RepoRoot 'src' 'FogApi.Cmdlets'
            foreach ($file in $emitted) {
                # Mirror the temp tree onto the real one: Models/Generated and
                # Cmdlets/Generated.
                $relative = $file.FullName.Substring($script:Scratch.Length).TrimStart('\', '/')
                $onDisk = Join-Path $realRoot $relative
                Test-Path -LiteralPath $onDisk |
                    Should -BeTrue -Because "$relative is in the spec but not in src/FogApi.Cmdlets"
                (Get-Content -LiteralPath $onDisk -Raw) |
                    Should -Be (Get-Content -LiteralPath $file.FullName -Raw) `
                    -Because "$relative has drifted from the emitter. Rerun spec/tools/New-FogCmdletSource.ps1."
            }
        }

        It 'declares nullable explicitly in every generated file' {
            # Roslyn treats a file whose first comment says auto-generated as
            # OUTSIDE the nullable context, so every string? in it is CS8669
            # even with Nullable enable set project-wide. Without the directive
            # the whole generated surface fails to compile.
            $generated = @(Get-ChildItem -LiteralPath (Join-Path $script:RepoRoot 'src' 'FogApi.Cmdlets') -Filter '*.cs' -Recurse |
                Where-Object { $_.FullName -match 'Generated' })
            $generated.Count | Should -BeGreaterThan 100
            foreach ($file in $generated) {
                (Get-Content -LiteralPath $file.FullName -Raw) |
                    Should -BeLike '*#nullable enable*' -Because "$($file.Name) is auto-generated and needs the directive"
            }
        }
    }

    Context 'the emitted PowerShell files' -Skip {
        # Kept, skipped, and deliberately not deleted: the .ps1 emitter still
        # exists and is what the Python and bash emitters were modelled on. This
        # comes back if any class is ever emitted as PowerShell again.
        It 'match what the emitter produces right now' {
            & (Join-Path $script:SpecRoot 'tools/New-FogApiFunctionFile.ps1') -Class printer -OutDir $script:Scratch | Out-Null
            $emitted = @(Get-ChildItem -LiteralPath $script:Scratch -Filter '*.ps1')
            $emitted.Count | Should -BeGreaterThan 0
            foreach ($file in $emitted) {
                $onDisk = Join-Path (Join-Path $script:RepoRoot 'FogApi') "Public/$($file.Name)"
                Test-Path -LiteralPath $onDisk | Should -BeTrue -Because "$($file.Name) is in the spec but not in Public"
                (Get-Content -LiteralPath $onDisk -Raw) | Should -Be (Get-Content -LiteralPath $file.FullName -Raw) -Because "$($file.Name) has been hand-edited. Change the spec or the emitter; an edit here is lost on the next run."
            }
        }

        It 'carries exactly one comment-based help block, first' {
            # Both build scripts locate the block by first-occurrence string
            # search, so a second block truncates the file at build time while
            # the source still looks fine.
            foreach ($fn in @($script:Spec.functions | Where-Object { $_.class -eq 'printer' })) {
                $path = Join-Path (Join-Path $script:RepoRoot 'FogApi') "Public/$($fn.functionName).ps1"
                $content = Get-Content -LiteralPath $path -Raw
                ([regex]::Matches($content, [regex]::Escape('<' + '#'))).Count | Should -Be 1
            }
        }
    }

    Context 'parameter aliases' {
        It 'renders every declared alias onto the parameter it names' {
            # Declared in the overlay rather than in the emitted file, because
            # the emitter overwrites what it emits -- an alias added to a
            # generated cmdlet by hand lasts until the next run and then
            # disappears with no error. This asserts the declaration actually
            # reaches the parameter.
            # Pester 6 refuses Mock -ModuleName when two modules share a name, and each
            # test file importing into its own scope makes that happen across a run.
            Remove-Module FogApi -Force -ErrorAction SilentlyContinue
            Import-Module (Join-Path $script:RepoRoot 'FogApi' 'FogApi.psd1') -Force
            $checked = 0
            foreach ($fn in $script:Spec.functions) {
                if ($fn.status -eq 'skipped-name-taken') { continue }
                $cmd = Get-Command $fn.functionName -ErrorAction SilentlyContinue
                if (-not $cmd) { continue }
                $classSchema = $script:Spec.schemas.($fn.class)
                if (-not $classSchema) { continue }
                foreach ($field in $classSchema.fields) {
                    if (-not $field.aliases -or $field.aliases.Count -eq 0) { continue }
                    if (-not $cmd.Parameters.ContainsKey($field.name)) { continue }
                    foreach ($alias in $field.aliases) {
                        $cmd.Parameters[$field.name].Aliases |
                            Should -Contain $alias -Because "$($fn.functionName) -$($field.name) declares the alias -$alias"
                        $checked++
                    }
                }
            }
            $checked | Should -BeGreaterThan 0 -Because 'the assertion above is worthless if it examined nothing'
        }

        It 'never aliases a parameter to the name of another parameter' {
            # An alias colliding with a real parameter name fails at import,
            # which is a late and confusing place to find out.
            # Pester 6 refuses Mock -ModuleName when two modules share a name, and each
            # test file importing into its own scope makes that happen across a run.
            Remove-Module FogApi -Force -ErrorAction SilentlyContinue
            Import-Module (Join-Path $script:RepoRoot 'FogApi' 'FogApi.psd1') -Force
            foreach ($fn in $script:Spec.functions) {
                $cmd = Get-Command $fn.functionName -ErrorAction SilentlyContinue
                if (-not $cmd) { continue }
                $real = @($cmd.Parameters.Keys)
                foreach ($p in $cmd.Parameters.Values) {
                    foreach ($alias in @($p.Aliases)) {
                        $real | Should -Not -Contain $alias -Because "$($fn.functionName) aliases -$($p.Name) to -$alias, which is already a parameter"
                    }
                }
            }
        }
    }

    Context 'the manifest' {
        It 'lists every file in Public and every alias declared in one' {
            { & (Join-Path $script:RepoRoot 'update-sourcemanifest.ps1') -Check } |
                Should -Not -Throw -Because 'run ./update-sourcemanifest.ps1 to resync'
        }
    }
}
