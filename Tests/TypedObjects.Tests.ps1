<#
    Guards the typed-object decision recorded in CONTEXT-api-coverage-plan.md,
    "Typed objects". The mechanism is ETS type data plus a PSTypeName stamp, and
    the two properties that decided it against real classes are the ones most
    easily lost by a well-meaning refactor:

      1. the stamp is ADDITIVE -- no field the server sent may move or disappear
      2. [PSTypeName()] actually rejects a wrong-shaped object

    Both are asserted here rather than left to the plan document.
#>

BeforeAll {
    $script:hostFixture = Join-Path $PSScriptRoot 'Fixtures/host.json'
}

Describe 'Register-FogTypeData' {

    It 'registers the FogApi.Host type name' {
        $td = Get-TypeData -TypeName 'FogApi.Host'
        $td | Should -Not -BeNullOrEmpty
    }

    It 'gives FogApi.Host a default display set so a 39-field object stays readable' {
        $td = Get-TypeData -TypeName 'FogApi.Host'
        $set = $td.DefaultDisplayPropertySet
        $set | Should -Not -BeNullOrEmpty
        $set.ReferencedProperties | Should -Contain 'name'
        $set.ReferencedProperties | Should -Contain 'id'
        # If this ever grows past a handful the table stops being readable, which
        # was the whole point of having a display set.
        $set.ReferencedProperties.Count | Should -BeLessOrEqual 6
    }

    It 'attaches the behaviour methods' {
        $members = (Get-TypeData -TypeName 'FogApi.Host').Members.Keys
        foreach ($m in 'Refresh','Deploy','Cancel','ToString') {
            $members | Should -Contain $m
        }
    }

    It 'is idempotent, so a re-import does not throw' {
        # Private, so reach into the module's own scope rather than exporting it
        # just to be testable.
        # -First 1, and the Script filter, because Get-Module FogApi does not
        # reliably return one thing. Every test file's BeforeAll imports the
        # module into its own Pester scope, so by the time several files have
        # run in one process this returns several -- and `& $mod { }` on an
        # array stringifies it, giving "The term 'FogApi FogApi' is not
        # recognized". The failure names no module and no import, so it reads
        # like a broken function rather than a scoping artifact.
        $mod = Get-Module FogApi | Where-Object ModuleType -eq 'Script' | Select-Object -First 1
        $mod | Should -Not -BeNullOrEmpty
        { & $mod { Register-FogTypeData; Register-FogTypeData } } | Should -Not -Throw
    }
}

Describe 'the FogApi.Host stamp is additive' {

    It 'preserves every property the server sent' {
        $raw = Get-Content $script:hostFixture -Raw | ConvertFrom-Json
        $before = $raw.PSObject.Properties.Name | Sort-Object

        $raw.PSObject.TypeNames.Insert(0, 'FogApi.Host')
        # ScriptProperties added by type data are additions, not replacements, so
        # compare as a subset rather than for equality.
        $after = $raw.PSObject.Properties.Name
        foreach ($p in $before) { $after | Should -Contain $p }
    }

    It 'keeps fields the OpenAPI Host schema does not declare' {
        # The reason a real class lost: components.schemas.Host declares 30
        # properties and a stock 1.6 host response carries 39, because the schema
        # reflects the model's own columns and the route returns its joins too.
        # macs and inventory are read by Get-FogHost itself.
        $raw = Get-Content $script:hostFixture -Raw | ConvertFrom-Json
        $raw.PSObject.TypeNames.Insert(0, 'FogApi.Host')
        foreach ($undeclared in 'macs','inventory') {
            $raw.PSObject.Properties.Name | Should -Contain $undeclared -Because `
                "$undeclared is absent from the schema but present in the response, and must survive"
        }
    }

    It 'reports the type name to callers' {
        $raw = Get-Content $script:hostFixture -Raw | ConvertFrom-Json
        $raw.PSObject.TypeNames.Insert(0, 'FogApi.Host')
        $raw.PSObject.TypeNames[0] | Should -Be 'FogApi.Host'
    }
}

Describe 'PSTypeName parameter validation' {

    BeforeAll {
        function Test-TakesFogHost {
            param([Parameter(Mandatory)][PSTypeName('FogApi.Host')]$InputObject)
            'bound'
        }
    }

    It 'binds an object carrying the type name' {
        $raw = Get-Content $script:hostFixture -Raw | ConvertFrom-Json
        $raw.PSObject.TypeNames.Insert(0, 'FogApi.Host')
        Test-TakesFogHost -InputObject $raw | Should -Be 'bound'
    }

    It 'rejects an object that does not carry it' {
        # A real class would have ACCEPTED this by coercing on property names,
        # which is why the class arm lost the validation goal it was meant to win.
        { Test-TakesFogHost -InputObject ([pscustomobject]@{ nope = 1 }) -ErrorAction Stop } |
            Should -Throw
    }
}

Describe 'Add-FogTypeName enumerates every collection shape a getter returns' {

    # Regression: Add-FogTypeName wrapped its input in @() before iterating, and
    # on pwsh 7.6.5 @($list) throws ArgumentException 'Argument types do not
    # match' for a [List[object]]. Get-FogHostGroup builds exactly that, so
    # stamping its return threw instead of returning groups -- caught by the
    # real-server suite, reproducible with no server at all.
    BeforeAll {
        # See the note in the idempotency test: Get-Module FogApi can return
        # more than one module once several test files have run in one process,
        # and & on the resulting array fails with a message that names neither.
        $script:fogModule = Get-Module FogApi | Where-Object ModuleType -eq 'Script' | Select-Object -First 1
        $script:stamp = {
            param($InputObject)
            & $script:fogModule {
                param($o) Add-FogTypeName -InputObject $o -TypeName 'FogApi.Group'
            } $InputObject
        }
    }

    It 'stamps a [List[object]], which is what Get-FogHostGroup builds' {
        $list = New-Object System.Collections.Generic.List[System.Object]
        $list.Add([pscustomobject]@{ id = 1; name = 'GroupA' })
        $list.Add([pscustomobject]@{ id = 2; name = 'GroupB' })

        $result = & $script:stamp $list

        @($result).Count | Should -Be 2
        foreach ($item in $result) {
            $item.PSObject.TypeNames[0] | Should -Be 'FogApi.Group'
        }
    }

    It 'stamps a plain array' {
        $result = & $script:stamp @([pscustomobject]@{ id = 1 }, [pscustomobject]@{ id = 2 })
        @($result).Count | Should -Be 2
        $result[1].PSObject.TypeNames[0] | Should -Be 'FogApi.Group'
    }

    It 'stamps a single object' {
        $result = & $script:stamp ([pscustomobject]@{ id = 1 })
        $result.PSObject.TypeNames[0] | Should -Be 'FogApi.Group'
    }

    It 'passes $null straight through' {
        & $script:stamp $null | Should -BeNullOrEmpty
    }

    It 'leaves a string alone rather than stamping every character' {
        # @() and foreach agree here, but the guard is load-bearing: a stamped
        # string would put the type name on each char of a collection.
        $result = & $script:stamp 'agroupname'
        $result | Should -Be 'agroupname'
        $result.PSObject.TypeNames[0] | Should -Not -Be 'FogApi.Group'
    }
}
