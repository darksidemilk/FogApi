#
# Get-LastImageTime used to read the imagingLog table. FOG 1.6 retired it
# (ADR 0022): taskLog was already written at the same points, for the same
# events, and the one fact imagingLog held alone -- which image ran -- is now
# taskLog.imageName. So the cmdlet reads taskLog.
#
# Three things about that are easy to get wrong and are asserted here:
#
#   1. taskLog records EVERY task state change, not just imaging. A row with no
#      imageName is not an imaging event and must not be reported as one -- the
#      fixture's newest row is deliberately a Wake Up with an empty imageName,
#      so a naive "take the last row" returns the wrong answer.
#   2. The timestamp is createdTime, which FOGController's
#      $databaseFieldsToIgnore hides from components.schemas.Tasklog while
#      save() still fills the column and the API still returns it. Reading a
#      field the schema does not declare is correct here, not a mistake.
#   3. It filters SERVER side. Nothing deletes taskLog rows, so pulling the
#      whole table to keep a handful got worse every day a server ran -- and
#      worse than slow, the unpaged list is capped at the server's MAX_ROWS
#      (10000) and truncates silently, so past that point the host's rows might
#      not be in the page at all and the cmdlet would report the wrong answer
#      with nothing to indicate rows had been dropped.
#      /tasklog/search/{item} still cannot help: search matches a name column
#      and taskLog has none. The list route's column filter can, and hostID is
#      one of taskLog's declared fields.
#

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1') -Force
    Import-Module (Join-Path $PSScriptRoot 'FogApi.TestHelpers.psm1') -Force
}

Describe 'Get-LastImageTime' {

    BeforeEach { Register-FogApiMock }

    It 'returns the most recent row that names an image, not simply the last row' {
        $log = Get-LastImageTime -hostId 42 6>$null
        $log | Should -Not -BeNullOrEmpty
        $log.imageName | Should -Be 'Win-10-21H2'
        # id 2 is newer but names no image; id 0 is older. Neither may win.
        $log.id | Should -Be 1
    }

    It 'reports createdTime, the column the schema does not declare' {
        $log = Get-LastImageTime -hostId 42 6>$null
        $log.createdTime | Should -Be '2026-08-18 12:19:38'
    }

    It 'reads taskLog, never the retired imaginglog' {
        Get-LastImageTime -hostId 42 6>$null | Out-Null
        Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 0 -ParameterFilter {
            $uriPath -match 'imaginglog'
        }
    }

    It 'lists rather than searching, because tasklog search cannot work' {
        # /tasklog/search/{item} matches a name column and taskLog has none, so
        # the route answers nothing however it is asked. FOG's own document does
        # not advertise search for taskLog, and correctly so.
        Get-LastImageTime -hostId 42 6>$null | Out-Null
        Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 0 -ParameterFilter {
            $uriPath -match 'tasklog/search/'
        }
        Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 1 -ParameterFilter {
            $uriPath -match '^tasklog'
        }
    }

    It 'asks the server for one host, rather than pulling the whole table' {
        # The point of the change. Without the filter this pulled every taskLog
        # row on the server and kept the matching handful, which is capped at
        # MAX_ROWS and truncates silently.
        Get-LastImageTime -hostId 42 6>$null | Out-Null
        Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 1 -ParameterFilter {
            $uriPath -match 'filter=hostID%3D42'
        }
    }

    It 'keeps the class name in the path when it adds the filter' {
        # `?` is a legal character in an unbraced PowerShell variable name, so
        # "$uri?$query" parses as the variable `uri?` -- which does not exist,
        # expands to empty, and silently drops the class from the path. That
        # shipped once; this is what catches it coming back.
        Get-LastImageTime -hostId 42 6>$null | Out-Null
        Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 1 -ParameterFilter {
            $uriPath -match '^tasklog\?'
        }
        Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 0 -ParameterFilter {
            $uriPath -match '^filter='
        }
    }

    # The "no imaging history" path is deliberately not tested here. It cannot be
    # reached through the mock: Get-FogHost resolves any id to the single host
    # fixture (42), so every call finds that host's rows no matter what id is
    # passed. Faking it would mean asserting against the mock's behaviour rather
    # than the cmdlet's. The filtering that path depends on -- a row without an
    # imageName is not an imaging event -- is already covered by the first test,
    # where the newest row is a Wake Up and correctly loses.
}
