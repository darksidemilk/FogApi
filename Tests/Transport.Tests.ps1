<#
The transport contract.

These assertions used to live in Tests/Invoke-FogApi.Tests.ps1, which mocked
Invoke-RestMethod one level below Invoke-FogApi. That seam does not survive the
move to compiled transport: there is no Invoke-RestMethod to mock any more, and
`Mock -ModuleName FogApi Invoke-FogApi` cannot reach a compiled cmdlet's
internals either -- Pester injects a mock into a module's session state and a
compiled cmdlet resolves nothing through session state.

That mock does not error, it just stops intercepting. It fails OPEN, which is
the dangerous direction: a run everyone believes is mocked would talk to
whatever server the local settings file names and mutate it. So the two seams
these tests drive are shipped features rather than test hooks --
[FogApi.Testing.CapturingHandler] for what a request looked like on the wire,
and Set-FogTransport for everything above it.

Requires the compiled assembly. Run ./build-dotnet.ps1 first, or dotnet build.
#>

BeforeDiscovery {
    $script:DllPath = Join-Path $PSScriptRoot '..' 'FogApi' 'bin' 'FogApi.Core.dll'
    $script:HaveDll = Test-Path -LiteralPath $script:DllPath
}

Describe 'FogApi transport' -Skip:(-not $script:HaveDll) {

    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..' 'FogApi' 'bin' 'FogApi.Core.dll') -Force

        # A real request while this is set throws. Every mocked test sets it,
        # because a transport mock that stopped intercepting is worse than no
        # mock: the suite goes green while talking to something real.
        $env:FOGAPI_FORBID_NETWORK = '1'

        function New-TestSettings {
            param([string]$Server = 'https://fog.example.com', [string]$Bearer)
            $s = [FogApi.FogServerSettings]::new()
            $s.FogServer = $Server
            # Already base64, the way the web UI issues them.
            $s.FogApiToken = 'QUJD'
            $s.FogUserToken = 'REVG'
            if ($Bearer) { $s.FogBearerToken = $Bearer }
            $s
        }

        function New-Transport {
            param($Handler, [string]$Server = 'https://fog.example.com', [string]$Bearer)
            # Build the settings NOW and close over the object. The Func is
            # invoked from inside Send(), by which point this function has
            # returned and $Server is out of scope -- a PowerShell scriptblock
            # captures by reference, not by value, so without GetNewClosure the
            # provider hands back a settings object with an empty FogServer and
            # the failure reads as a product bug rather than a harness one.
            $settings = New-TestSettings -Server $Server -Bearer $Bearer
            $provider = { $settings }.GetNewClosure()
            [FogApi.FogHttpTransport]::new($Handler, [Func[FogApi.FogServerSettings]]$provider)
        }
    }

    AfterAll {
        [FogApi.FogTransport]::Reset()
        Remove-Item Env:FOGAPI_FORBID_NETWORK -ErrorAction SilentlyContinue
    }

    Context 'the base URI' {
        It 'defaults a bare hostname to http and appends the webroot' {
            (New-TestSettings -Server 'fog-server').BaseUri() | Should -Be 'http://fog-server/fog/'
        }

        It 'keeps an explicit scheme' {
            (New-TestSettings -Server 'https://fog.example.com').BaseUri() |
                Should -Be 'https://fog.example.com/fog/'
        }

        It 'tolerates a trailing slash on the configured server' {
            (New-TestSettings -Server 'https://fog.example.com/').BaseUri() |
                Should -Be 'https://fog.example.com/fog/'
        }

        It 'does not mangle a double slash inside the path' {
            # Invoke-FogApi normalised with .Replace('//','/') and then put the
            # scheme back, which also collapsed any legitimate double slash
            # further along. A filter value is allowed to contain one.
            $h = [FogApi.Testing.CapturingHandler]::new('{}')
            $t = New-Transport -Handler $h
            $null = $t.Send([FogApi.FogRequest]::new('host/list/name=a//b', 'GET', $null))
            "$($h.LastRequestUri)" | Should -Be 'https://fog.example.com/fog/host/list/name=a//b'
        }
    }

    Context 'credentials' {
        It 'sends both tokens verbatim' {
            # The router base64_decode()s these, which reads as though a client
            # should encode. It must not: the value the UI shows is already
            # encoded. Re-encoding 401s every call and is hard to spot, because
            # hex is itself valid base64.
            $h = [FogApi.Testing.CapturingHandler]::new('{}')
            $t = New-Transport -Handler $h
            $null = $t.Send([FogApi.FogRequest]::new('host/1234', 'GET', $null))
            $h.LastHeaders['fog-api-token']  | Should -Be 'QUJD'
            $h.LastHeaders['fog-user-token'] | Should -Be 'REVG'
        }

        It 'sends a Bearer credential instead of the header pair' {
            # ADR 0027: sufficient on its own. Sending both would work but would
            # muddy which credential an audit entry actually accepted.
            $h = [FogApi.Testing.CapturingHandler]::new('{}')
            $t = New-Transport -Handler $h -Bearer 'fog_deadbeef'
            $null = $t.Send([FogApi.FogRequest]::new('host', 'GET', $null))
            $h.LastHeaders['Authorization'] | Should -Be 'Bearer fog_deadbeef'
            $h.LastHeaders.ContainsKey('fog-api-token') | Should -BeFalse
        }
    }

    Context 'errors' {
        It "surfaces FOG's message rather than the status line" {
            # The whole reason FogApiException exists. Invoke-FogApi caught the
            # failure and retried through Invoke-WebRequest, which cost a second
            # round trip and replaced this message with "Response status code
            # does not indicate success: 406".
            $h = [FogApi.Testing.CapturingHandler]::new(
                '{"error":"Invalid hostname; must be 1-15 of these characters"}', 406)
            $t = New-Transport -Handler $h
            { $t.Send([FogApi.FogRequest]::new('host', 'POST', '{"name":"x"}')) } |
                Should -Throw -ExpectedMessage '*Invalid hostname; must be 1-15 of these characters*'
        }

        It 'surfaces a non-JSON error body instead of discarding it' {
            $h = [FogApi.Testing.CapturingHandler]::new('<html>PHP Fatal error</html>', 500)
            $t = New-Transport -Handler $h
            { $t.Send([FogApi.FogRequest]::new('x', 'GET', $null)) } |
                Should -Throw -ExpectedMessage '*PHP Fatal error*'
        }

        It 'rejects a fogServer that is still the template prose' {
            $bad = [FogApi.FogServerSettings]::new()
            $bad.FogServer = 'your fog server hostname or ip address'
            { $bad.BaseUri() } | Should -Throw -ExpectedMessage '*Set-FogServerSettings*'
        }
    }

    Context 'command resolution' {
        It 'is shadowed by the script function of the same name, which is why the .ps1 must go' {
            # Found the hard way: running this file after FogApiSpec.Tests.ps1
            # in the same session sent four tests to FogApi/Public/Invoke-FogApi.ps1
            # instead of the compiled cmdlet, because a FUNCTION beats a CMDLET
            # in PowerShell's resolution order. Set-FogTransport was ignored and
            # a real HTTP request went out to the configured server. It failed
            # only because of a certificate mismatch.
            #
            # FOGAPI_FORBID_NETWORK does not save that case: the .ps1 transport
            # has never heard of it. So the guard protects the compiled path and
            # nothing else, and the two implementations cannot coexist under one
            # name. When Invoke-FogApi becomes a cmdlet, Public/Invoke-FogApi.ps1
            # is deleted in the SAME commit -- there is no safe overlap window,
            # and the failure mode is a live request rather than an error.
            $all = @(Get-Command Invoke-FogApi -All -ErrorAction SilentlyContinue)
            $cmdlets = @($all | Where-Object CommandType -eq 'Cmdlet')
            $cmdlets.Count | Should -BeGreaterThan 0 -Because 'the compiled Invoke-FogApi should be loaded'

            if (@($all | Where-Object CommandType -eq 'Function').Count -gt 0) {
                Set-ItResult -Inconclusive -Because @'
both implementations are loaded in this session, so the function is winning.
That is the coexistence hazard this test documents, not a product failure --
the tests below bind the cmdlet explicitly to stay deterministic.
'@
            }
        }
    }

    Context 'Invoke-FogApi over a replaced transport' {

        BeforeAll {
            # Bound explicitly, not by name. If the script module is also loaded
            # its function shadows this, and these tests would silently exercise
            # the old transport and reach the network. See the context above.
            $script:InvokeFogApi = Get-Command Invoke-FogApi -CommandType Cmdlet
        }

        It 'parses a JSON object the way ConvertFrom-Json would' {
            # Every existing script that consumes this cmdlet was written
            # against that shape.
            Set-FogTransport -ScriptBlock { param($p, $m, $j) '{"id":42,"name":"lab-01"}' }
            $r = & $script:InvokeFogApi -uriPath host/42
            $r.id | Should -Be 42
            $r.name | Should -Be 'lab-01'
        }

        It 'keeps an id whole rather than turning it into a double' {
            Set-FogTransport -ScriptBlock { param($p, $m, $j) '{"id":123456789}' }
            (& $script:InvokeFogApi -uriPath x).id | Should -BeOfType [long]
        }

        It 'treats an empty body as success' {
            # FOG answers task and cancel with a two byte body. Treating that as
            # a parse failure would break every one of them.
            Set-FogTransport -ScriptBlock { param($p, $m, $j) '' }
            & $script:InvokeFogApi -uriPath host/1/task -Method POST -jsonData '{}' | Should -BeNullOrEmpty
        }

        It 'counts the calls that reached the mock' {
            # The assertion that catches a cmdlet which acquired a code path
            # bypassing FogTransport.Current.
            $t = Set-FogTransport -PassThru -ScriptBlock { param($p, $m, $j) '{}' }
            $null = & $script:InvokeFogApi -uriPath a
            $null = & $script:InvokeFogApi -uriPath b
            $t.CallCount | Should -Be 2
        }

        It 'warns when a GET carries a body' {
            Set-FogTransport -ScriptBlock { param($p, $m, $j) '{}' }
            $w = $null
            $null = & $script:InvokeFogApi -uriPath x -Method GET -jsonData '{"a":1}' -WarningVariable w -WarningAction SilentlyContinue
            "$w" | Should -BeLike '*POST*'
        }

        It 'refuses a method FOG does not serve' {
            { & $script:InvokeFogApi -uriPath x -Method FETCH } | Should -Throw
        }
    }

    Context 'the network guard' {
        It 'throws instead of making a real request when FOGAPI_FORBID_NETWORK is set' {
            # This is the backstop for the failure mode that is silent by
            # nature: a mock that installed successfully and intercepted
            # nothing.
            [FogApi.FogTransport]::Reset()
            { & (Get-Command Invoke-FogApi -CommandType Cmdlet) -uriPath host/1 } |
                Should -Throw -ExpectedMessage '*FOGAPI_FORBID_NETWORK*'
        }
    }

    Context 'the settings file' {
        It 'resolves the same path Get-FogServerSettingsFile does' {
            $expected = if ($IsLinux -or $IsMacOS) {
                Join-Path $HOME '.FogApi' 'api-settings.json'
            } else {
                Join-Path $env:APPDATA 'FogApi' 'api-settings.json'
            }
            [FogApi.FogServerSettings]::ResolvePath() | Should -Be $expected
        }

        It 'names the file it could not find' {
            { [FogApi.FogServerSettings]::Load('/nope/missing.json') } |
                Should -Throw -ExpectedMessage '*missing.json*'
        }

        It 'rejects the shipped template rather than 401ing later' {
            $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "fogapi-$([guid]::NewGuid().ToString('N')).json"
            try {
                Get-Content (Join-Path $PSScriptRoot '..' 'FogApi' 'lib' 'settings.json') -Raw |
                    Set-Content $tmp -NoNewline
                { [FogApi.FogServerSettings]::Load($tmp) } |
                    Should -Throw -ExpectedMessage '*placeholder*'
            } finally {
                Remove-Item $tmp -ErrorAction SilentlyContinue
            }
        }

        It 'reads a bearer token when one is configured' {
            $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "fogapi-$([guid]::NewGuid().ToString('N')).json"
            try {
                '{"fogApiToken":"QUJD","fogUserToken":"REVG","fogServer":"fog","fogBearerToken":"fog_x"}' |
                    Set-Content $tmp -NoNewline
                $s = [FogApi.FogServerSettings]::Load($tmp)
                $s.UsesBearer | Should -BeTrue
                $s.FogBearerToken | Should -Be 'fog_x'
            } finally {
                Remove-Item $tmp -ErrorAction SilentlyContinue
            }
        }

        It 'stays compatible with a settings file that predates bearer support' {
            $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "fogapi-$([guid]::NewGuid().ToString('N')).json"
            try {
                '{"fogApiToken":"QUJD","fogUserToken":"REVG","fogServer":"fog"}' | Set-Content $tmp -NoNewline
                $s = [FogApi.FogServerSettings]::Load($tmp)
                $s.UsesBearer | Should -BeFalse
            } finally {
                Remove-Item $tmp -ErrorAction SilentlyContinue
            }
        }
    }
}
