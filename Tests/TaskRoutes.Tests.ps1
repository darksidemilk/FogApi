#
# The tasking routes: /current, /{id}/task and /{id}/cancel.
#
# These three shapes had no mock at all, so nineteen documented examples failed
# against a module that was working correctly. The mock now answers them by
# convention, and the answers come from a live 1.6 server rather than from
# somebody's idea of what a tasking route ought to return:
#
#   POST   /host/{id}/task     200, body ""   -- and the task IS created
#   DELETE /host/{id}/cancel   200, body ""   -- on a genuinely active task
#   DELETE /host/{id}/cancel   409 {"msg":"Host has no active task to cancel"}
#   GET    /task/current       the same list envelope a list route returns
#
# Probed against 1.6.0-beta.3894 with a throwaway host on a locally-administered
# MAC, so nothing could PXE boot into the task; the fixture is cancelled and
# deleted on the way out. Repeat with
# scripts/background_scripts/probe_task_cancel_shapes.sh.
#
# WHY THE PATHS ARE ASSERTED HERE. /current is DERIVED from the class's list
# fixture, which is what stops the documented example and the mocked answer
# drifting apart -- but it also makes a /current response identical to a plain
# list response, so no assertion on the RESULT can tell you which route was
# asked for. That fact belongs on the request, so it is pinned here. Without
# this, an active-task cmdlet that quietly started paging the whole table would
# still pass every example test.
#

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1') -Force
    Import-Module (Join-Path $PSScriptRoot 'FogApi.TestHelpers.psm1') -Force
}

Describe 'active-task cmdlets ask for /current' {

    BeforeEach { Register-FogApiMock }

    $cases = @(
        @{ Cmdlet = 'Get-ActiveFogTasks';             Class = 'task' }
        @{ Cmdlet = 'Get-ActiveFogScheduledTasks';    Class = 'scheduledtask' }
        @{ Cmdlet = 'Get-ActiveFogMulticastSessions'; Class = 'multicastsession' }
        @{ Cmdlet = 'Get-ActiveFogPowerManagements';  Class = 'powermanagement' }
    )

    It '<Cmdlet> requests <Class>/current and not the plain list' -ForEach $cases {
        & $Cmdlet | Out-Null
        Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 1 -ParameterFilter {
            $uriPath -eq "$Class/current"
        }
        Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 0 -ParameterFilter {
            $uriPath -eq $Class
        }
    }

    It 'returns the rows, not the envelope' {
        # Regression guard for the bug fixed in 80d5be7: these four were the only
        # getters that skipped .data, so the type name landed on the envelope.
        $rows = @(Get-ActiveFogTasks)
        $rows.Count | Should -Be 1
        $rows[0].PSObject.Properties.Name | Should -Not -Contain 'recordsTotal'
        $rows[0].id | Should -Be 1
    }
}

Describe 'task and cancel' {

    BeforeEach { Register-FogApiMock }

    It 'Start-FogHostTask posts to host/{id}/task' {
        Start-FogHostTask -id 1 -TaskRequest @{ taskTypeID = 1 } | Out-Null
        Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 1 -ParameterFilter {
            $uriPath -eq 'host/1/task' -and $Method -eq 'POST'
        }
    }

    It 'Stop-FogHostTask deletes host/{id}/cancel' {
        Stop-FogHostTask -id 1 | Out-Null
        Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 1 -ParameterFilter {
            $uriPath -eq 'host/1/cancel' -and $Method -eq 'DELETE'
        }
    }

    It 'answers both with an empty body, which is what the server does' {
        # Pinned as a literal because the temptation is to "fix" this into
        # something that looks like a created object -- which is exactly the
        # invented shape (task-create.json, {"id":501,"success":true}) that made
        # three documented examples fail against their own module. FOG returns
        # no body here and carries no task id back; read /task/current for that.
        (Start-FogHostTask -id 1 -TaskRequest @{ taskTypeID = 1 }) | Should -BeNullOrEmpty
        (Stop-FogHostTask -id 1) | Should -BeNullOrEmpty
    }

    It 'covers every tasking class, not just the two that had hand-written arms' {
        # host and group were mapped by hand; multicastsession, scheduledtask and
        # task were not, and every one of their examples failed with "no fixture
        # mapped". Convention covers all of them now.
        Start-FogMulticastSessionTask -id 1 -TaskRequest @{ taskTypeID = 1 } | Out-Null
        Start-FogScheduledTaskTask    -id 1 -TaskRequest @{ taskTypeID = 1 } | Out-Null
        Start-FogTaskTask             -id 1 -TaskRequest @{ taskTypeID = 1 } | Out-Null
        Stop-FogMulticastSessionTask  -id 1 | Out-Null
        Stop-FogScheduledTaskTask     -id 1 | Out-Null
        Stop-FogTaskTask              -id 1 | Out-Null
        Stop-FogGroupTask             -id 1 | Out-Null
        foreach ($p in @('multicastsession/1/task', 'scheduledtask/1/task', 'task/1/task',
                         'multicastsession/1/cancel', 'scheduledtask/1/cancel', 'task/1/cancel',
                         'group/1/cancel')) {
            Should -Invoke Invoke-FogApi -ModuleName FogApi -Times 1 -ParameterFilter {
                $uriPath -eq $p
            }
        }
    }
}
