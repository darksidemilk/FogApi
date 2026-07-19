#
# Generates an informational parameter-set coverage report - NOT a pass/fail gate.
# See docs/Contributing.md for the Expected output: testing standard this measures against.
# Always mocked (regardless of -RealServer) since it only needs to resolve dynamic parameters
# (which call Get-FogVersion under the hood, see Tests/FogApi.TestHelpers.psm1), not exercise
# real server behavior.
#
param(
    [switch]$RealServer,
    [string[]]$Function,
    [string]$CoverageReportPath = (Join-Path $PSScriptRoot '..' 'TestResults' 'coverage-report.md')
)

BeforeAll {
    $moduleManifest = Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1'
    Import-Module $moduleManifest -Force
    Import-Module (Join-Path $PSScriptRoot 'FogApi.TestHelpers.psm1') -Force
}

Describe 'FogApi parameter-set coverage report (informational)' {
    It 'writes a coverage report to CoverageReportPath' {
        try {
            Register-FogApiMock

            $manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1')
            $allFunctions = $manifest.FunctionsToExport
            if ($Function) {
                $allFunctions = $allFunctions | Where-Object { $_ -in $Function }
            }

            $coverage = Get-FogParameterSetCoverage -FunctionName $allFunctions
            $markdown = ConvertTo-FogCoverageMarkdown -Coverage $coverage

            $outputDir = Split-Path $CoverageReportPath -Parent
            if ($outputDir -and !(Test-Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            Set-Content -Path $CoverageReportPath -Value $markdown
        } catch {
            Write-Warning "Coverage report generation failed (non-blocking): $($_.Exception.Message)"
        }

        # Intentionally unconditional: this report is informational only and must never
        # fail the build, regardless of what happened above - see docs/Contributing.md.
        $true | Should -BeTrue
    }
}
