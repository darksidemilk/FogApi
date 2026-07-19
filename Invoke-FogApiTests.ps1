
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

#Requires -Modules Pester

<#

.DESCRIPTION
 Runs the FogApi Pester test suite under .\Tests. By default Invoke-FogApi is mocked with fixture
 data from .\Tests\Fixtures so this runs fast and deterministically with no external dependency -
 this is the same script the build-test.yml GitHub Action runs (with -CI) on every pull request.

 .PARAMETER RealServer
 Skip mocking and run the exact same tests against a real, already-configured Fog server, using
 whatever Get-FogServerSettings / the local api-settings.json already has configured on this machine.
 Not used by CI. Note that some examples (New-FogHost, Send-FogWolTask, Update-FogObject) will really
 create/modify/message objects on that server.

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

#>

[CmdletBinding()]
Param(
	[switch]$RealServer,
	[switch]$CI,
	[string]$OutputPath = ".\TestResults\pester-results.xml",
	[string[]]$Function,
	[string]$CoverageReportPath = ".\TestResults\coverage-report.md"
)

if (-not (Get-Module -ListAvailable -Name Pester | Where-Object Version -ge '5.0.0')) {
	"Pester 5+ not found, installing for current user..." | Out-Host;
	Install-Module -Name Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module Pester -MinimumVersion 5.0.0 -Force

Remove-Module FogApi -Force -ea 0
Import-Module "$PSScriptRoot\FogApi\FogApi.psd1" -Force

if ($RealServer) {
	Write-Warning "Running with -RealServer: examples run unmocked against whatever Fog server is configured in this user's api-settings.json. Some examples create/modify/message real objects."
}

$containerData = @{ RealServer = [bool]$RealServer; CoverageReportPath = $CoverageReportPath }
if ($Function) {
	$containerData.Function = $Function
}

$container = New-PesterContainer -Path "$PSScriptRoot\Tests" -Data $containerData

$config = New-PesterConfiguration
$config.Run.Container = $container
$config.Output.Verbosity = 'Detailed'

if ($CI) {
	$outputDir = Split-Path $OutputPath -Parent
	if ($outputDir -and !(Test-Path $outputDir)) {
		mkdir $outputDir -Force | Out-Null
	}
	$config.TestResult.Enabled = $true
	$config.TestResult.OutputFormat = 'NUnitXml'
	$config.TestResult.OutputPath = $OutputPath
	$config.Run.Exit = $true
}

Invoke-Pester -Configuration $config
