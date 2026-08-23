# Real-server validation history

Which integration tests (Tests/FogApi.RealServer.Tests.ps1) have actually been run against a real, configured Fog server, and when they were last confirmed - maintained by `Update-FogRealServerValidationLedger`, merged in each time someone runs `.\Invoke-FogApiTests.ps1 -RealServer` and commits the result. A test missing from this page has never been run against a real server.

## FogApi real-server integration > Connectivity

- [x] `Get-FogVersion returns a non-empty version string` - last validated 2026-08-23, Passed
- [x] `Test-FogVerAbove1dot6 returns a boolean` - last validated 2026-08-23, Passed

## FogApi real-server integration > Group lifecycle

- [x] `Add-FogHostGroup associates the host and Get-FogHostGroup reflects it` - last validated 2026-08-23, Passed
- [x] `created a real group with a real id` - last validated 2026-08-23, Passed
- [x] `Remove-FogHostGroup removes the association` - last validated 2026-08-23, Passed
- [x] `Update-FogGroup changes the description` - last validated 2026-08-23, Passed

## FogApi real-server integration > Host lifecycle

- [x] `created a real host with a real id` - last validated 2026-08-23, Passed
- [x] `Get-FogHost finds the created host by name` - last validated 2026-08-23, Passed
- [x] `Get-FogHosts includes the created host` - last validated 2026-08-23, Passed
- [x] `Update-FogObject changes a field and Get-FogHost reflects it back` - last validated 2026-08-23, Passed

## FogApi real-server integration > Host mac lifecycle

- [x] `Add-FogHostMac adds a second mac and Get-FogHostMacs reflects it` - last validated 2026-08-23, Passed

## FogApi real-server integration > Read-only structural contracts

- [x] `Get-FogImages does not throw` - last validated 2026-08-23, Passed
- [x] `Get-FogModules returns an array of id/name-shaped modules` - last validated 2026-08-23, Passed
- [x] `Get-FogSetting resolves a known setting by name` - last validated 2026-08-23, Passed
- [x] `Get-FogSettings returns an array of id/name-shaped settings` - last validated 2026-08-23, Passed
- [x] `Get-FogSnapins does not throw` - last validated 2026-08-23, Passed
- [x] `Get-FogVersion is at least major version 1` - last validated 2026-08-23, Passed

