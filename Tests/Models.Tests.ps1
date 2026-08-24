<#
The entity model contract.

FOG's OpenAPI::_entitySchema() reflects a model's own $databaseFields -- its
columns -- while the route returns that entity JOINED to its relations. host
declares 33 and answers with 39. 80 such fields across 24 classes, and the
document names them only in an English sentence.

That gap is the whole reason these types derive from DynamicObject rather than
being plain POCOs, so the tests that matter here are the ones that prove the
gap is covered: an undeclared field must survive the round trip, resolve by
name, and not vanish from JSON output.

Nothing here touches the network.
#>

BeforeDiscovery {
    $script:DllPath = Join-Path $PSScriptRoot '..' 'FogApi' 'bin' 'FogApi.Core.dll'
    $script:HaveDll = Test-Path -LiteralPath $script:DllPath
}

Describe 'FogEntity' -Skip:(-not $script:HaveDll) {

    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..' 'FogApi' 'bin' 'FogApi.Core.dll') -Force

        # Shaped like what host answers with: declared columns, plus computed
        # fields that are not columns, one of them a nested object.
        $script:Json = '{"id":7,"name":"Win11","description":"d",' +
                       '"macs":["aa:bb","cc:dd"],"primac":"aa:bb","inventory":{"sysuuid":"ABC-123"}}'

        function New-Entity {
            [System.Text.Json.JsonSerializer]::Deserialize[FogApi.Models.FogOs](
                $script:Json, [FogApi.FogJson]::Wire)
        }
    }

    Context 'declared fields' {
        It 'lands on real typed properties' {
            $o = New-Entity
            $o.id | Should -Be 7
            $o.id | Should -BeOfType [long]
            $o.name | Should -Be 'Win11'
        }

        It 'reads an integer FOG sent as a string' {
            # Values come out of MySQL as strings, so an integer column arrives
            # as "42" about as often as 42.
            $o = [System.Text.Json.JsonSerializer]::Deserialize[FogApi.Models.FogOs](
                '{"id":"42"}', [FogApi.FogJson]::Wire)
            $o.id | Should -Be 42
        }

        It 'reads an empty string as null rather than zero' {
            # An unset foreign key would otherwise look like a real id of 0.
            $o = [System.Text.Json.JsonSerializer]::Deserialize[FogApi.Models.FogOs](
                '{"id":""}', [FogApi.FogJson]::Wire)
            $o.id | Should -BeNullOrEmpty
        }
    }

    Context 'undeclared fields' {
        It 'keeps every one the server sent' {
            (New-Entity).GetUndeclaredFieldNames() | Should -Be @('macs', 'primac', 'inventory')
        }

        It 'resolves one by name' {
            (New-Entity).primac | Should -Be 'aa:bb'
        }

        It 'resolves case-insensitively, the way PowerShell members do' {
            (New-Entity).PRIMAC | Should -Be 'aa:bb'
        }

        It 'resolves through a nested one' {
            # $h.inventory.sysuuid is a real access pattern in this module, and
            # it is the one an IDictionary based bag cannot serve.
            (New-Entity).inventory.sysuuid | Should -Be 'ABC-123'
        }

        It 'returns an array as an array' {
            @((New-Entity).macs).Count | Should -Be 2
        }

        It 'answers null for a name nobody sent, like a PSCustomObject' {
            (New-Entity).nosuchfield | Should -BeNullOrEmpty
        }

        It 'accepts an assignment to a field the server did send' {
            $o = New-Entity
            $o.primac = 'ff:ee'
            $o.primac | Should -Be 'ff:ee'
            $o.GetDirtyFields() | Should -Contain 'primac'
        }

        It 'refuses an assignment to a name nobody sent' {
            # A typo should say so rather than creating a phantom field that
            # silently never reaches the server.
            $o = New-Entity
            { $o.notAField = 'x' } | Should -Throw -ExpectedMessage "*cannot be found*"
        }
    }

    Context 'serialisation' {
        It 'emits only data through ConvertTo-Json, not the entity plumbing' {
            # Map, FogClass and the dirty set are internal precisely so this
            # stays readable. They were public once and ConvertTo-Json returned
            # the whole field table with the data buried inside it.
            $json = (New-Entity) | ConvertTo-Json -Compress -Depth 3
            $json | Should -Not -BeLike '*"Map"*'
            $json | Should -Not -BeLike '*FogClass*'
            $json | Should -BeLike '*"name":"Win11"*'
        }

        It 'drops undeclared fields through ConvertTo-Json, which is why ToJson exists' {
            # Measured behaviour of PowerShell's serialiser against a
            # DynamicObject, asserted so nobody re-discovers it as a bug.
            ((New-Entity) | ConvertTo-Json -Compress -Depth 3) | Should -Not -BeLike '*primac*'
        }

        It 'keeps undeclared fields through ToJson' {
            $json = (New-Entity).ToJson()
            $json | Should -BeLike '*"primac":"aa:bb"*'
            $json | Should -BeLike '*"sysuuid":"ABC-123"*'
        }

        It 'does not throw on an entity carrying a nested computed field' {
            # It did. Storing the PowerShell projection in the bag put PSObjects
            # in the graph, and serialising one walks its Members and
            # OverloadDefinitions until System.Text.Json reports an object
            # cycle. The bag holds the raw JsonNode for this reason.
            { (New-Entity).ToJson() } | Should -Not -Throw
        }
    }

    Context 'dirty tracking' {
        It 'starts clean, because deserialising is not a user edit' {
            # Otherwise every field would look assigned and the first update
            # would send the whole object back, including values the caller
            # never touched.
            (New-Entity).GetDirtyFields() | Should -BeNullOrEmpty
        }

        It 'records only what was assigned' {
            $o = New-Entity
            $o.description = 'changed'
            $o.GetDirtyFields() | Should -Be @('description')
        }

        It 'sends only what was assigned' {
            # FOG's edit route MERGES. A field the body does not mention is left
            # alone, so sending an unassigned one as "" is data loss.
            $o = New-Entity
            $o.description = 'changed'
            $o.ToPatch().ToJsonString() | Should -Be '{"description":"changed"}'
        }
    }
}

Describe 'FogField wire rules' -Skip:(-not $script:HaveDll) {

    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..' 'FogApi' 'bin' 'FogApi.Core.dll') -Force
        $script:Flag = [FogApi.Models.FogField]::new(
            'pending', 'hostPending', [FogApi.Models.FogWire]::Bool01)
    }

    It 'sends a boolean as the string 0 or 1' {
        # FOG spells every boolean column enum('0','1'). A JSON true is a
        # different request.
        $script:Flag.ToWire($true).ToJsonString()  | Should -Be '"1"'
        $script:Flag.ToWire($false).ToJsonString() | Should -Be '"0"'
    }

    It 'accepts the string form unchanged' {
        $script:Flag.ToWire('1').ToJsonString() | Should -Be '"1"'
    }

    It 'refuses a number that is neither 0 nor 1' {
        # The deploySnapins lesson, generalised. That field is
        # oneOf [string, integer, boolean] and its values are -1 (every snapin),
        # 0 (none) or a snapin id. Reading it as a boolean turned -1 into true
        # and queued a different snapin task, silently. Never guess what a
        # number meant.
        { $script:Flag.ToWire(-1) } | Should -Throw -ExpectedMessage '*0/1 column*'
    }

    It 'reads MySQL zero date as null rather than throwing' {
        # FOG answers an unset datetime column with 0000-00-00 00:00:00, which
        # is not a date and which DateTime.Parse refuses.
        [FogApi.Models.FogField]::FromFogDateTime('0000-00-00 00:00:00') | Should -BeNullOrEmpty
    }

    It 'reads a real date' {
        [FogApi.Models.FogField]::FromFogDateTime('2026-08-18 12:19:38') |
            Should -Be ([datetime]'2026-08-18 12:19:38')
    }

    It 'carries the maxLength the spec declares' {
        ([FogApi.Models.FogOs]::FieldMap['name']).MaxLength | Should -Be 30
    }
}
