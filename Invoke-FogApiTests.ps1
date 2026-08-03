
<#PSScriptInfo

.VERSION 1.0.0.0

.GUID 8f2b2e2a-2f7a-4c7a-9d6a-6b9b6a2b3f10

.AUTHOR JJ Fullmer

.COMPANYNAME FogProject

.COPYRIGHT 2026

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

		1.0.0.0
			Initial version

.PRIVATEDATA

#>

<#

.DESCRIPTION
 Runs the FogApi Pester test suite under .\Tests. By default Invoke-FogApi is mocked with fixture
 data from .\Tests\Fixtures so this runs fast and deterministically with no external dependency -
 this is the same script the build-test.yml GitHub Action runs (with -CI) on every pull request.

 Deliberately has no #Requires -Modules Pester clause - the version check/install logic just below
 already enforces Pester 6+ explicitly, and a #Requires clause on the same module Invoke-Pester is
 later called from has been observed to silently break `exit`'s process exit code propagating out
 of this script (reproduced locally: with the clause present, -CI still ran and reported failures
 correctly but always exited 0). Don't add one back without re-verifying that.

 .PARAMETER RealServer
 Also runs Tests/FogApi.RealServer.Tests.ps1, a hand-written integration suite (not derived from
 doc examples) against a real, already-configured Fog server, using whatever Get-FogServerSettings /
 the local api-settings.json already has configured on this machine. Not used by CI. It dynamically
 creates/discovers real objects to test against rather than assuming fixture ids/names exist on your
 server, and really creates/modifies objects there - see the -RealServer safety net note below.

 .PARAMETER CI
 Emit machine-readable NUnitXml test results to -OutputPath and exit with a non-zero code on any
 test failure, for use in the GitHub Action.

 .PARAMETER OutputPath
 Where to write the NUnitXml results when -CI is specified. Defaults to .\TestResults\pester-results.xml

 .PARAMETER Function
 Optional list of function names to narrow the example test cases down to, for a targeted local run.

 .PARAMETER CoverageReportPath
 Where to write the informational parameter-set coverage report (see docs/Contributing.md). Always
 generated as a side effect of the run - never affects pass/fail. Defaults to .\TestResults\coverage-report.md

 .PARAMETER RealServerJournalPath
 Only used with -RealServer. Every mutating call an example makes against the real server is journaled
 here as it happens (so a mid-run crash still leaves a recoverable record), then replayed in reverse once
 the run finishes to revert edits and delete created objects - see Restore-FogRealServerState in
 Tests/FogApi.TestHelpers.psm1. Defaults to .\TestResults\realserver-journal.ndjson

 .PARAMETER TestResultsReportPath
 Where to write a human-readable, published-quality markdown test-results report (one checklist per
 source file, pass/fail and duration per test) - the same shape previously hand-copied into
 docs/TestValidation.md, now generated for real every run. Defaults to .\TestResults\test-results.md

 .PARAMETER RealServerValidationPath
 Only used with -RealServer. Path to the durable, source-controlled JSON ledger of which examples have
 actually been run against a real Fog server and when - merged (not overwritten) on every -RealServer
 run, so a targeted -Function run doesn't erase history for everything else. A markdown page rendered
 from it is written alongside it (same name, .md extension) for browsing/publishing - see
 Update-FogRealServerValidationLedger in Tests/FogApi.TestHelpers.psm1. Defaults to
 .\docs\RealServerValidation.json / .\docs\RealServerValidation.md. Unlike the other report paths this
 is meant to be committed to source control, not treated as disposable build output.

#>

[CmdletBinding()]
Param(
	[switch]$RealServer,
	[switch]$CI,
	[string]$OutputPath = ".\TestResults\pester-results.xml",
	[string[]]$Function,
	[string]$CoverageReportPath = ".\TestResults\coverage-report.md",
	[string]$RealServerJournalPath = ".\TestResults\realserver-journal.ndjson",
	[string]$TestResultsReportPath = ".\TestResults\test-results.md",
	[string]$RealServerValidationPath = ".\docs\RealServerValidation.json",
	[string]$repository = "PSGallery"
)

if (-not (Get-Module -ListAvailable -Name Pester | Where-Object Version -ge '6.0.0')) {
	"Pester 5+ not found, installing for current user..." | Out-Host;
	Install-Module -Name Pester -MinimumVersion 6.0.0 -Scope CurrentUser -Force -SkipPublisherCheck -Repository $repository
}
Import-Module Pester -MinimumVersion 6.0.0 -Force

Remove-Module FogApi -Force -ea 0
Import-Module "$PSScriptRoot\FogApi\FogApi.psd1" -Force
Import-Module "$PSScriptRoot\Tests\FogApi.TestHelpers.psm1" -Force

if ($RealServer) {
	Write-Warning "Running with -RealServer: Tests/FogApi.RealServer.Tests.ps1 runs against whatever Fog server is configured in this user's api-settings.json, creating/modifying real objects there (the fixture-driven example suite still runs mocked as usual - it's not run against a real server). Every mutating call is journaled to '$RealServerJournalPath' and auto-reverted/deleted after the run finishes (see Restore-FogRealServerState). A few real-world actions (dispatched deploy/capture/snapin/WoL tasks) can't be undone and will be listed as such once the run completes."
}

$containerData = @{ RealServer = [bool]$RealServer; CoverageReportPath = $CoverageReportPath; RealServerJournalPath = $RealServerJournalPath }
if ($Function) {
	$containerData.Function = $Function
}

$container = New-PesterContainer -Path "$PSScriptRoot\Tests" -Data $containerData

$config = New-PesterConfiguration
$config.Run.Container = $container
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'

if ($CI) {
	$outputDir = Split-Path $OutputPath -Parent
	if ($outputDir -and !(Test-Path $outputDir)) {
		mkdir $outputDir -Force | Out-Null
	}
	$config.TestResult.Enabled = $true
	$config.TestResult.OutputFormat = 'NUnitXml'
	$config.TestResult.OutputPath = $OutputPath
}

# Not using $config.Run.Exit here (even under -CI) - it would terminate the process the moment
# Invoke-Pester returns, before the reports below ever get written. -CI's build-failing behavior
# is instead reproduced explicitly at the very end, once everything has been generated.
$result = Invoke-Pester -Configuration $config

$generatedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm')
$reportDir = Split-Path $TestResultsReportPath -Parent
if ($reportDir -and !(Test-Path $reportDir)) {
	mkdir $reportDir -Force | Out-Null
}
ConvertTo-FogTestResultsMarkdown -Tests $result.Tests -RealServer:$RealServer -GeneratedAt $generatedAt | Set-Content -Path $TestResultsReportPath
"Test results report written to $TestResultsReportPath" | Out-Host

if ($RealServer) {
	$realServerTests = @($result.Tests | Where-Object { (Split-Path $_.ScriptBlock.File -Leaf) -eq 'FogApi.RealServer.Tests.ps1' })
	$markdownValidationPath = [System.IO.Path]::ChangeExtension($RealServerValidationPath, '.md')
	Update-FogRealServerValidationLedger -LedgerPath $RealServerValidationPath -MarkdownPath $markdownValidationPath -Tests $realServerTests -RunDate (Get-Date).ToString('yyyy-MM-dd') | Out-Null
	"Real-server validation ledger updated: $RealServerValidationPath / $markdownValidationPath" | Out-Host
}

if ($CI -and $result.FailedCount -gt 0) {
	exit 1
}
