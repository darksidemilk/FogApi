#
# -Filter sends FOG's server-side column filter.
#
# FOG's generic read routes -- list, count, names and ids -- have always taken a
# column filter. FOG only started ADVERTISING it in 1.6.0-beta.3894
# (FOGProject/fogproject b25193faf), which is why the module never used it: the
# document described it in prose, only on `list`, and with the syntax wrong
# ("field:value pairs" when the server parses field=value), so following the
# documentation returned 400 and the feature looked absent. Get-LastImageTime
# paged the whole of taskLog and filtered client side as a result.
#
# The wire format is the part worth testing. It is a query string nested inside
# ONE query parameter, so the inner `=` and `&` have to be encoded as a unit or
# the outer parser eats them. Getting that wrong does not error -- it produces a
# filter the server reads differently, or a 400 naming a field nobody typed.
#

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1') -Force
    Import-Module (Join-Path $PSScriptRoot 'FogApi.TestHelpers.psm1') -Force
}

Describe 'ConvertTo-FogFilterQuery' {

    It 'encodes a single pair as one query parameter value' {
        $q = InModuleScope FogApi { ConvertTo-FogFilterQuery -Filter @{ hostID = 42 } }
        $q | Should -Be 'filter=hostID%3D42'
    }

    It 'encodes the joining & so the outer query does not split on it' {
        $q = InModuleScope FogApi { ConvertTo-FogFilterQuery -Filter @{ hostID = 42; type = 'error' } }
        # Hashtable ordering is not guaranteed, so assert the properties that
        # matter rather than one literal string.
        $q | Should -BeLike 'filter=*'
        $q | Should -Match 'hostID%3D42'
        $q | Should -Match 'type%3Derror'
        $q | Should -Match '%26'
        # A bare & would end the filter value at the outer parser.
        ($q -replace '^filter=', '') | Should -Not -Match '&'
    }

    It 'joins an array with commas, which is the server "any of these"' {
        $q = InModuleScope FogApi { ConvertTo-FogFilterQuery -Filter @{ stateID = @(1, 3) } }
        # The comma must survive as a comma: parse_str does not split on %2C.
        [uri]::UnescapeDataString($q) | Should -Be 'filter=stateID=1,3'
    }

    It 'returns empty for an empty filter, so callers append nothing' {
        $q = InModuleScope FogApi { ConvertTo-FogFilterQuery -Filter @{} }
        $q | Should -BeNullOrEmpty
    }
}

Describe 'Get-FogObject -Filter' {

    BeforeEach { Register-FogApiMock }

    It 'puts the filter on the list route and keeps the class in the path' {
        Get-FogObject -type object -coreObject tasklog -Filter @{ hostID = 42 } | Out-Null
        Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 1 -ParameterFilter {
            $uriPath -match '^tasklog\?filter=hostID%3D42'
        }
    }

    It 'applies to the count, names and ids sub-routes too' {
        foreach ($sub in @('count', 'names', 'ids')) {
            Get-FogObject -type object -coreObject tasklog -Filter @{ hostID = 42 } -subPath $sub | Out-Null
        }
        foreach ($sub in @('count', 'names', 'ids')) {
            Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 1 -ParameterFilter {
                $uriPath -match "^tasklog/$sub\?filter="
            }
        }
    }

    It 'survives paging, which appends its own query parameters' {
        # Get-FogPagedResult used to hardcode `?start=`, which on an already
        # filtered path produced tasklog?filter=x?start=0 -- read by the server
        # as a filter value of "x?start=0" and rejected as an unknown field.
        Get-FogObject -type object -coreObject tasklog -Filter @{ hostID = 42 } | Out-Null
        Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 1 -ParameterFilter {
            $uriPath -match 'filter=hostID%3D42&start=0'
        }
        Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 0 -ParameterFilter {
            $uriPath -match '\?.*\?'
        }
    }

    It 'refuses a filter alongside an id, which already names one row' {
        { Get-FogObject -type object -coreObject tasklog -IDofObject 1 -Filter @{ hostID = 42 } } |
            Should -Throw -ExpectedMessage '*mutually exclusive*'
    }

    It 'refuses a filter on the active-task route, which does not read one' {
        { Get-FogObject -type objectactivetasktype -coreActiveTaskObject task -Filter @{ hostID = 42 } } |
            Should -Throw
    }

    It 'sends no filter parameter at all when none was asked for' {
        Get-FogObject -type object -coreObject tasklog | Out-Null
        Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 0 -ParameterFilter {
            $uriPath -match 'filter='
        }
    }
}
