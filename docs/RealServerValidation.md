# Real-server validation history

Which integration tests (Tests/FogApi.RealServer.Tests.ps1) have actually been run against a real, configured Fog server, and when they were last confirmed - maintained by `Update-FogRealServerValidationLedger`, merged in each time someone runs `.\Invoke-FogApiTests.ps1 -RealServer` and commits the result. A test missing from this page has never been run against a real server.

## FogApi against a real server > a full lifecycle, on a class that is safe to write

- [x] `accepts the object itself down the pipeline, not just an id` - last validated 2026-08-24, Passed
- [x] `appears in a list of the class` - last validated 2026-08-24, Passed
- [x] `creates and returns a typed object with a server-assigned id` - last validated 2026-08-24, Passed
- [x] `deletes` - last validated 2026-08-24, Passed
- [x] `finds it by search` - last validated 2026-08-24, Passed
- [x] `is counted` - last validated 2026-08-24, Passed
- [x] `reads the same row back by id` - last validated 2026-08-24, Passed
- [x] `updates only the fields that were bound` - last validated 2026-08-24, Passed

## FogApi against a real server > errors carry what the server said

- [x] `surfaces the message, not just the status code` - last validated 2026-08-24, Passed
- [x] `treats an empty body as success rather than a parse failure` - last validated 2026-08-24, Passed

## FogApi against a real server > paging

- [x] `agrees with the ids route` - last validated 2026-08-24, Passed
- [x] `returns every row when not limited` - last validated 2026-08-24, Passed
- [x] `stops early when asked for fewer rows than exist` - last validated 2026-08-24, Passed

## FogApi against a real server > read shapes, across every class the spec knows

- [x] `<Cmdlet> -Count returns a number` - last validated 2026-08-24, Passed
- [x] `<Cmdlet> lists without throwing, and returns typed rows` - last validated 2026-08-24, Passed

## FogApi against a real server > the fields FOG returns but does not declare

- [x] `keeps them on the typed model` - last validated 2026-08-24, Passed
- [x] `keeps them through ToJson, where ConvertTo-Json drops them` - last validated 2026-08-24, Passed

## FogApi against a real server > the server answers at all

- [x] `accepts the configured credentials on a route that needs them` - last validated 2026-08-24, Passed
- [x] `publishes its paging bounds, which is what a client should size requests from` - last validated 2026-08-24, Passed
- [x] `reports a version` - last validated 2026-08-24, Passed

## FogApi against a real server > validation comes from the spec, and the server agrees with it

- [x] `accepts a name exactly at the limit` - last validated 2026-08-24, Passed
- [x] `refuses a name longer than the column` - last validated 2026-08-24, Passed

## FogApi against a real server > wire types, verified against real rows

- [x] `reads a 0/1 column as a boolean` - last validated 2026-08-24, Passed
- [x] `reads a datetime column as a DateTime, or null for the zero date` - last validated 2026-08-24, Passed

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

