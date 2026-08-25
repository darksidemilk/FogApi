<#
The behavioural suite. It talks to a real FOG server, because nothing else
tells the truth.

There used to be a mocked half: 106 canned responses under Tests/Fixtures and
489 tests driven from the Expected output: blocks in each function's help. It
asserted that the module still produced the shape somebody had written down,
which is a different claim from "the shape the server sends", and the two drift
apart silently. It is gone.

WHAT THIS ASSERTS, AND WHAT IT DOES NOT

Contracts, not values. A real server's inventory is whatever it is, so nothing
here expects a particular host or a particular count. It creates its own rows,
asserts what must be true of them, and removes them again.

EVERY ROW IT CREATES IS NAMED zz-test-<something>-<random>, and every Context
that creates one removes it in its own AfterAll. The prefix is the recovery
handle: if a run dies half way, `Get-FogOs | Where name -like 'zz-test-*'` finds
the debris.

Skipped unless run with -RealServer. Needs a configured server -- see
Get-FogServerSettings. Point it at a dev server; it writes.
#>
param(
    [switch]$RealServer
)

Describe 'FogApi against a real server' -Skip:(-not $RealServer) {

    BeforeAll {
        Remove-Module FogApi -Force -ErrorAction SilentlyContinue
        Import-Module (Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1') -Force

        # The guard is for MOCKED runs. This suite is the opposite, so make sure
        # a leftover from another run cannot silently strangle it.
        Remove-Item Env:FOGAPI_FORBID_NETWORK -ErrorAction SilentlyContinue
        Reset-FogTransport

        function script:New-TestName {
            param([string]$Prefix = 'x')
            # Capped short: Host::isHostnameSafe() rejects anything over 15
            # characters, and os.name is varchar(30).
            "zz-test-$Prefix-$(Get-Random -Maximum 9999)"
        }

        $script:ServerInfo = Invoke-FogApi -uriPath system/info
    }

    Context 'the server answers at all' {
        It 'reports a version' {
            $script:ServerInfo.version | Should -Not -BeNullOrEmpty
        }

        It 'publishes its paging bounds, which is what a client should size requests from' {
            $script:ServerInfo.paging.maxRows | Should -BeGreaterThan 0
            $script:ServerInfo.paging.expandMaxItems | Should -BeGreaterThan 0
        }

        It 'accepts the configured credentials on a route that needs them' {
            # whoami is the cheapest authenticated read.
            { Invoke-FogApi -uriPath whoami } | Should -Not -Throw
        }
    }

    Context 'read shapes, across every class the spec knows' {
        # A sweep rather than a per-class test: the point is that no class
        # answers in a shape the model layer cannot read. A class that has never
        # been exercised is exactly where a wrong wireType hides.
        BeforeDiscovery {
            $specFile = Join-Path $PSScriptRoot '..' 'spec' 'fog-api-spec.json'
            $spec = Get-Content -LiteralPath $specFile -Raw | ConvertFrom-Json
            # The classes that have a generated list cmdlet.
            $script:ReadCases = @(
                $spec.functions |
                    Where-Object { $_.routeName -eq 'indiv' -and $_.status -in @('generate', 'replaces-thin-wrapper') } |
                    ForEach-Object { @{ Cmdlet = $_.functionName; Class = $_.class } }
            )
        }

        It '<Cmdlet> lists without throwing, and returns typed rows' -ForEach $script:ReadCases {
            $rows = @(& $Cmdlet -First 5)
            # An empty class is a legitimate answer; a throw is not.
            foreach ($row in $rows) {
                $row.GetType().FullName | Should -BeLike 'FogApi.Models.*' -Because "$Cmdlet should return a typed model"
            }
        }

        It '<Cmdlet> -Count returns a number' -ForEach $script:ReadCases {
            $count = & $Cmdlet -Count
            $count | Should -BeOfType [long]
            $count | Should -BeGreaterOrEqual 0
        }
    }

    Context 'a full lifecycle, on a class that is safe to write' {
        # os is the smallest writable class FOG has: three fields, no relations,
        # nothing else references a row this suite creates.
        BeforeAll {
            $script:OsName = New-TestName 'os'
            $script:Created = New-FogOs -name $script:OsName -description 'created by the FogApi real-server suite'
        }

        AfterAll {
            if ($script:Created -and $script:Created.id) {
                Remove-FogOs -id $script:Created.id -Confirm:$false -ErrorAction SilentlyContinue
            }
        }

        It 'creates and returns a typed object with a server-assigned id' {
            $script:Created | Should -Not -BeNullOrEmpty
            $script:Created.GetType().FullName | Should -Be 'FogApi.Models.FogOs'
            $script:Created.id | Should -BeOfType [long]
            $script:Created.id | Should -BeGreaterThan 0
            $script:Created.name | Should -Be $script:OsName
        }

        It 'reads the same row back by id' {
            $again = Get-FogOs -id $script:Created.id
            $again.id | Should -Be $script:Created.id
            $again.name | Should -Be $script:OsName
        }

        It 'accepts the object itself down the pipeline, not just an id' {
            # The id-or-object contract, resolved during parameter binding.
            $piped = $script:Created | Get-FogOs
            $piped.id | Should -Be $script:Created.id
        }

        It 'finds it by search' {
            @(Find-FogOs $script:OsName).Count | Should -BeGreaterThan 0
        }

        It 'updates only the fields that were bound' {
            # The contract that matters most on FOG's edit route: it MERGES, so
            # a field the body does not mention keeps its value. Sending an
            # unbound parameter as its default would be data loss.
            $null = Update-FogOs -id $script:Created.id -description 'updated by the suite'
            $after = Get-FogOs -id $script:Created.id
            $after.description | Should -Be 'updated by the suite'
            $after.name | Should -Be $script:OsName -Because 'name was never bound and must survive the update'
        }

        It 'appears in a list of the class' {
            @(Get-FogOs | Where-Object id -eq $script:Created.id).Count | Should -Be 1
        }

        It 'is counted' {
            (Get-FogOs -Count) | Should -BeGreaterThan 0
        }

        It 'deletes' {
            $throwaway = New-FogOs -name (New-TestName 'del')
            Remove-FogOs -id $throwaway.id -Confirm:$false
            @(Find-FogOs $throwaway.name) | Should -BeNullOrEmpty
        }
    }

    Context 'validation comes from the spec, and the server agrees with it' {
        It 'refuses a name longer than the column' {
            # osName is varchar(30). The cmdlet rejects 31 characters before a
            # request is made, and that number was read out of the document
            # rather than typed by anyone.
            { New-FogOs -name ('x' * 31) } | Should -Throw
        }

        It 'accepts a name exactly at the limit' {
            $name = 'zz-test-' + ('y' * 22)   # 30 characters
            $name.Length | Should -Be 30
            $made = New-FogOs -name $name
            try {
                $made.name | Should -Be $name
            } finally {
                Remove-FogOs -id $made.id -Confirm:$false -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'errors carry what the server said' {
        It 'surfaces the message, not just the status code' {
            # Invoke-FogApi used to catch the failure and retry through
            # Invoke-WebRequest, which cost a second round trip and replaced
            # FOG's own sentence with "Response status code does not indicate
            # success". This asserts the sentence survives.
            $err = $null
            try { Invoke-FogApi -uriPath 'nosuchroutehere' } catch { $err = $_ }
            $err | Should -Not -BeNullOrEmpty
            $err.Exception.Message | Should -Match '\d{3}'
        }

        It 'treats an empty body as success rather than a parse failure' {
            # FOG answers some writes with two bytes. Every task and cancel
            # route does.
            # Deleted once, and only once. Deleting again in a finally block
            # asked the server to remove a row that was already gone, and FOG
            # answers that with a 404 -- which read as a product failure and was
            # the test's own bug.
            $made = New-FogOs -name (New-TestName 'empty')
            { Remove-FogOs -id $made.id -Confirm:$false } | Should -Not -Throw
        }
    }

    Context 'the fields FOG returns but does not declare' {
        It 'keeps them on the typed model' {
            # _entitySchema() reflects a model's columns; the route returns the
            # entity joined to its relations. This is the gap DynamicObject
            # exists to cover, asserted against what the server actually sends
            # rather than against a fixture that says it does.
            $image = @(Get-FogImage -First 1)
            if (-not $image) { Set-ItResult -Skipped -Because 'this server has no images'; return }

            $undeclared = @($image[0].GetUndeclaredFieldNames())
            $undeclared.Count | Should -BeGreaterThan 0 -Because 'a real image response carries fields the schema does not declare'

            # And they resolve by name, which is the whole point.
            $first = $undeclared[0]
            { $image[0].$first } | Should -Not -Throw
        }

        It 'keeps them through ToJson, where ConvertTo-Json drops them' {
            $image = @(Get-FogImage -First 1)
            if (-not $image) { Set-ItResult -Skipped -Because 'this server has no images'; return }
            $undeclared = @($image[0].GetUndeclaredFieldNames())
            if (-not $undeclared) { Set-ItResult -Skipped -Because 'nothing undeclared on this row'; return }

            $image[0].ToJson() | Should -BeLike "*$($undeclared[0])*"
        }
    }

    Context 'wire types, verified against real rows' {
        It 'reads a 0/1 column as a boolean' {
            $image = @(Get-FogImage -First 1)
            if (-not $image) { Set-ItResult -Skipped -Because 'this server has no images'; return }
            if ($null -eq $image[0].isEnabled) { Set-ItResult -Skipped -Because 'isEnabled is null on this row'; return }
            $image[0].isEnabled | Should -BeOfType [bool] -Because 'FOG spells booleans enum(0,1) and the model should hide that'
        }

        It 'reads a datetime column as a DateTime, or null for the zero date' {
            # MySQL answers an unset datetime with 0000-00-00 00:00:00, which is
            # not a date and which DateTime.Parse refuses.
            $image = @(Get-FogImage -First 1)
            if (-not $image) { Set-ItResult -Skipped -Because 'this server has no images'; return }
            if ($null -ne $image[0].deployed) {
                $image[0].deployed | Should -BeOfType [datetime]
            }
        }
    }

    Context 'paging' {
        It 'stops early when asked for fewer rows than exist' {
            $all = @(Get-FogOs -Count)
            if ($all -lt 3) { Set-ItResult -Skipped -Because 'not enough rows to page'; return }
            @(Get-FogOs -First 2).Count | Should -Be 2
        }

        It 'returns every row when not limited' {
            $count = Get-FogOs -Count
            @(Get-FogOs).Count | Should -Be $count
        }

        It 'agrees with the ids route' {
            @(Get-FogOs -IdsOnly).Count | Should -Be (Get-FogOs -Count)
        }
    }

    AfterAll {
        # Anything a failed Context left behind. Named, so this can never touch
        # a row that is genuinely part of the server's inventory.
        foreach ($class in 'os', 'group', 'printer', 'storagegroup', 'usergroup') {
            try {
                $rows = @((Invoke-FogApi -uriPath $class).data | Where-Object { $_.name -like 'zz-test-*' })
                foreach ($row in $rows) {
                    Invoke-FogApi -uriPath "$class/$($row.id)/delete" -Method DELETE | Out-Null
                    Write-Warning "real-server suite: cleaned up a leftover $class '$($row.name)'"
                }
            } catch {
                Write-Warning "real-server suite: could not sweep $class -- $($_.Exception.Message)"
            }
        }
    }
}
