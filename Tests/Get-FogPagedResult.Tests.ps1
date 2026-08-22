#
# Dedicated tests for the FOG 1.6 paging walk.
#
# FOG 1.6 (commit dd40b7d0e) caps any list request that sends no paging params
# at MAX_ROWS = 10000, silently and with no error. FogApi sent no paging params,
# so every list cmdlet truncated at 10000 rows against a current 1.6 server.
# Get-FogObject now always sends explicit ?start=N&length=N and follows the
# server's nextUrl until it is null.
#
# These assert the *request sequence*, not just the assembled result - the
# sequence is the actual API contract and is what a future python port has to
# reproduce. Mocks Invoke-FogApi (the single transport seam) so no server is
# needed. Always runs mocked, regardless of -RealServer.
#
# Accepts the same container Data as the other files under Tests/ (see
# Invoke-FogApiTests.ps1) even though it doesn't use them, so a shared
# New-PesterContainer -Data call doesn't fail parameter binding here.
#
param(
    [switch]$RealServer,
    [string[]]$Function,
    [string]$CoverageReportPath
)

BeforeAll {
    $moduleManifest = Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1'
    Import-Module $moduleManifest -Force

    # A FOG 1.6 list envelope. paginate() sets the four *Url keys and
    # recordsReturned; their presence is how the client tells 1.6 from 1.5.
    function New-FogPageEnvelope {
        param($Rows, $NextUrl, [int]$Filtered)
        [PSCustomObject]@{
            draw            = 0
            recordsTotal    = $Filtered
            recordsFiltered = $Filtered
            truncated       = $false
            data            = $Rows
            _lang           = 'host'
            recordsReturned = @($Rows).Count
            firstUrl        = '/fog/host?start=0&length=1000'
            prevUrl         = $null
            nextUrl         = $NextUrl
            lastUrl         = '/fog/host?start=0&length=1000'
        }
    }

    # Get-DynmicParam calls Get-FogVersion while binding the -coreObject dynamic
    # parameter, so every Get-FogObject call probes the server version before it
    # issues the call the caller actually asked for. These mocks answer those
    # probes with a fixed version and keep them out of the recorded request list
    # so the assertions below describe only the data requests.
    $script:VersionProbePaths = @('system/info', 'service/getversion.php')

    function New-FogTestRows {
        param([int]$From, [int]$Count)
        if ($Count -le 0) { return @() }
        1..$Count | ForEach-Object { [PSCustomObject]@{ id = $From + $_ - 1; name = "h$($From + $_ - 1)" } }
    }
}

Describe 'Get-FogObject paging' {

    Context 'FOG 1.6 multi-page walk' {
        BeforeEach {
            $script:Requests = [System.Collections.Generic.List[string]]::new()
            Mock -ModuleName FogApi Invoke-FogApi {
                if ($uriPath -in $script:VersionProbePaths) { return [PSCustomObject]@{ version = '1.6.0' } }
                $script:Requests.Add($uriPath)
                switch -regex ($uriPath) {
                    'start=0&'    { return (New-FogPageEnvelope (New-FogTestRows 1 1000)    'host?start=1000&length=1000' 2500) }
                    'start=1000&' { return (New-FogPageEnvelope (New-FogTestRows 1001 1000) 'host?start=2000&length=1000' 2500) }
                    'start=2000&' { return (New-FogPageEnvelope (New-FogTestRows 2001 500)  $null 2500) }
                }
            }
        }

        It 'collects every row across all pages' {
            $r = Get-FogObject -type object -coreObject host
            $r.data.Count | Should -Be 2500
            $r.data[0].id | Should -Be 1
            $r.data[2499].id | Should -Be 2500
        }

        It 'issues one request per page and advances start each time' {
            Get-FogObject -type object -coreObject host | Out-Null
            $script:Requests.Count | Should -Be 3
            $script:Requests[0] | Should -Be 'host?start=0&length=1000'
            $script:Requests[1] | Should -Be 'host?start=1000&length=1000'
            $script:Requests[2] | Should -Be 'host?start=2000&length=1000'
        }

        It 'reports the assembled count and clears the per-page links' {
            $r = Get-FogObject -type object -coreObject host
            $r.count | Should -Be 2500
            $r.recordsReturned | Should -Be 2500
            $r.recordsFiltered | Should -Be 2500
            $r.nextUrl | Should -BeNullOrEmpty
        }
    }

    Context 'the MAX_ROWS truncation this fixes' {
        BeforeEach {
            Mock -ModuleName FogApi Invoke-FogApi {
                if ($uriPath -in $script:VersionProbePaths) { return [PSCustomObject]@{ version = '1.6.0' } }
                switch -regex ($uriPath) {
                    'start=0&'     { return (New-FogPageEnvelope (New-FogTestRows 1 10000)     'host?start=10000&length=10000' 12000) }
                    'start=10000&' { return (New-FogPageEnvelope (New-FogTestRows 10001 2000)  $null 12000) }
                }
            }
        }

        It 'returns all 12000 rows rather than stopping at the 10000 row cap' {
            $r = Get-FogObject -type object -coreObject host -PageSize 10000
            $r.data.Count | Should -Be 12000
        }
    }

    Context 'FOG 1.5 responses, which have no paging envelope' {
        BeforeEach {
            $script:Requests = [System.Collections.Generic.List[string]]::new()
            Mock -ModuleName FogApi Invoke-FogApi {
                if ($uriPath -in $script:VersionProbePaths) { return [PSCustomObject]@{ version = '1.6.0' } }
                $script:Requests.Add($uriPath)
                return [PSCustomObject]@{ count = 10; hosts = (New-FogTestRows 1 10) }
            }
        }

        It 'makes exactly one request and returns the whole list' {
            $r = Get-FogObject -type object -coreObject host
            $script:Requests.Count | Should -Be 1
            $r.data.Count | Should -Be 10
            $r.count | Should -Be 10
        }

        It 'applies -Skip and -First client side since the server ignored them' {
            $r = Get-FogObject -type object -coreObject host -Skip 3 -First 4
            $r.data.Count | Should -Be 4
            $r.data[0].id | Should -Be 4
        }
    }

    Context 'First, Skip and PageSize' {
        BeforeEach {
            $script:Requests = [System.Collections.Generic.List[string]]::new()
            Mock -ModuleName FogApi Invoke-FogApi {
                if ($uriPath -in $script:VersionProbePaths) { return [PSCustomObject]@{ version = '1.6.0' } }
                $script:Requests.Add($uriPath)
                switch -regex ($uriPath) {
                    'start=0&'    { return (New-FogPageEnvelope (New-FogTestRows 1 1000)    'host?start=1000&length=1000' 5000) }
                    'start=1000&' { return (New-FogPageEnvelope (New-FogTestRows 1001 1000) 'host?start=2000&length=1000' 5000) }
                    default       { return (New-FogPageEnvelope (New-FogTestRows 9999 1)    $null 5000) }
                }
            }
        }

        It '-First stops requesting once it has enough' {
            $r = Get-FogObject -type object -coreObject host -First 5
            $r.data.Count | Should -Be 5
            $script:Requests.Count | Should -Be 1
        }

        It '-First spanning a page boundary keeps paging until satisfied' {
            $r = Get-FogObject -type object -coreObject host -First 1500
            $r.data.Count | Should -Be 1500
            $script:Requests.Count | Should -Be 2
        }

        It '-Skip becomes the start param' {
            Get-FogObject -type object -coreObject host -Skip 250 -First 1 | Out-Null
            $script:Requests[0] | Should -Be 'host?start=250&length=1000'
        }

        It '-PageSize becomes the length param' {
            Get-FogObject -type object -coreObject host -PageSize 25 -First 1 | Out-Null
            $script:Requests[0] | Should -Be 'host?start=0&length=25'
        }
    }

    Context 'pages smaller than requested' {
        BeforeEach {
            $script:Requests = [System.Collections.Generic.List[string]]::new()
            # the ?expand path forces length to EXPAND_MAX_ITEMS server side, so a
            # page can come back smaller than asked for without meaning "done"
            Mock -ModuleName FogApi Invoke-FogApi {
                if ($uriPath -in $script:VersionProbePaths) { return [PSCustomObject]@{ version = '1.6.0' } }
                $script:Requests.Add($uriPath)
                switch -regex ($uriPath) {
                    'start=0&'   { return (New-FogPageEnvelope (New-FogTestRows 1 300)   'host?start=300&length=1000' 600) }
                    'start=300&' { return (New-FogPageEnvelope (New-FogTestRows 301 300) $null 600) }
                }
            }
        }

        It 'advances by rows actually returned, not by the requested length' {
            $r = Get-FogObject -type object -coreObject host
            $r.data.Count | Should -Be 600
            $script:Requests[1] | Should -Be 'host?start=300&length=1000'
        }
    }

    Context 'loop safety' {
        It 'stops when a page is empty even though nextUrl is still set' {
            $script:Requests = [System.Collections.Generic.List[string]]::new()
            Mock -ModuleName FogApi Invoke-FogApi {
                if ($uriPath -in $script:VersionProbePaths) { return [PSCustomObject]@{ version = '1.6.0' } }
                $script:Requests.Add($uriPath)
                return (New-FogPageEnvelope @() 'host?start=999&length=1000' 50)
            }

            Get-FogObject -type object -coreObject host | Out-Null

            $script:Requests.Count | Should -Be 1
        }
    }

    Context 'calls that must not be paged' {
        BeforeEach {
            $script:Requests = [System.Collections.Generic.List[string]]::new()
            Mock -ModuleName FogApi Invoke-FogApi {
                if ($uriPath -in $script:VersionProbePaths) { return [PSCustomObject]@{ version = '1.6.0' } }
                $script:Requests.Add($uriPath)
                return (New-FogPageEnvelope (New-FogTestRows 1 1) $null 1)
            }
        }

        It 'does not add paging params when fetching one object by id' {
            Get-FogObject -type object -coreObject host -IDofObject '42' | Out-Null
            $script:Requests[0] | Should -Be 'host/42'
        }

        It 'does not add paging params to an active task call' {
            Get-FogObject -type objectactivetasktype -coreActiveTaskObject task | Out-Null
            $script:Requests[0] | Should -Be 'task/current'
        }

        It '-NoAutoPage makes a single unpaged request' {
            Get-FogObject -type object -coreObject host -NoAutoPage | Out-Null
            $script:Requests.Count | Should -Be 1
            $script:Requests[0] | Should -Be 'host'
        }
    }
}
