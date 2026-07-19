#
# Dedicated tests for Invoke-FogApi itself - this is the seam every other
# test in this suite mocks, so it can't be verified by mocking itself.
# Mocks one level lower instead: Get-FogServerSettings (the settings file
# read) and Invoke-RestMethod (the actual HTTP call). Always runs mocked,
# regardless of -RealServer, since it is what verifies the seam itself.
#
# Accepts the same container Data as the other files under Tests/ (see
# Invoke-FogApiTests.ps1) even though it doesn't use them, so a shared
# New-PesterContainer -Data call doesn't fail parameter binding here.
param(
    [switch]$RealServer,
    [string[]]$Function,
    [string]$CoverageReportPath
)

BeforeAll {
    $moduleManifest = Join-Path $PSScriptRoot '..' 'FogApi' 'FogApi.psd1'
    Import-Module $moduleManifest -Force
}

Describe 'Invoke-FogApi' {
    Context 'URI construction' {
        BeforeEach {
            Mock -ModuleName FogApi Get-FogServerSettings {
                [PSCustomObject]@{
                    fogApiToken  = 'test-api-token'
                    fogUserToken = 'test-user-token'
                    fogServer    = 'fog-server'
                }
            }
        }

        It 'builds a normalized http:// uri for a bare server name' {
            Mock -ModuleName FogApi Invoke-RestMethod {
                $script:CapturedUri = $Uri
                return [PSCustomObject]@{ ok = $true }
            }

            Invoke-FogApi -uriPath 'host/1234' -Method Get | Out-Null

            $script:CapturedUri | Should -Be 'http://fog-server/fog/host/1234'
        }

        It 'leaves an https:// server as-is' {
            Mock -ModuleName FogApi Get-FogServerSettings {
                [PSCustomObject]@{
                    fogApiToken  = 'test-api-token'
                    fogUserToken = 'test-user-token'
                    fogServer    = 'https://fog-server'
                }
            }
            Mock -ModuleName FogApi Invoke-RestMethod {
                $script:CapturedUri = $Uri
                return [PSCustomObject]@{ ok = $true }
            }

            Invoke-FogApi -uriPath 'host' -Method Get | Out-Null

            $script:CapturedUri | Should -Be 'https://fog-server/fog/host'
        }
    }

    Context 'headers' {
        BeforeEach {
            Mock -ModuleName FogApi Get-FogServerSettings {
                [PSCustomObject]@{
                    fogApiToken  = 'test-api-token'
                    fogUserToken = 'test-user-token'
                    fogServer    = 'fog-server'
                }
            }
            Mock -ModuleName FogApi Invoke-RestMethod {
                $script:CapturedHeaders = $Headers
                return [PSCustomObject]@{ ok = $true }
            }
        }

        It 'sends the fog-api-token and fog-user-token headers from settings' {
            Invoke-FogApi -uriPath 'host' -Method Get | Out-Null

            $script:CapturedHeaders['fog-api-token'] | Should -Be 'test-api-token'
            $script:CapturedHeaders['fog-user-token'] | Should -Be 'test-user-token'
        }
    }

    Context 'request body' {
        BeforeEach {
            Mock -ModuleName FogApi Get-FogServerSettings {
                [PSCustomObject]@{
                    fogApiToken  = 'test-api-token'
                    fogUserToken = 'test-user-token'
                    fogServer    = 'fog-server'
                }
            }
        }

        It 'omits the body entirely when jsonData is empty' {
            Mock -ModuleName FogApi Invoke-RestMethod {
                $script:CapturedBody = $Body
                return [PSCustomObject]@{ ok = $true }
            }

            Invoke-FogApi -uriPath 'host' -Method Get | Out-Null

            $script:CapturedBody | Should -BeNullOrEmpty
        }

        It 'passes jsonData through as the body when supplied' {
            Mock -ModuleName FogApi Invoke-RestMethod {
                $script:CapturedBody = $Body
                return [PSCustomObject]@{ ok = $true }
            }

            Invoke-FogApi -uriPath 'host' -Method Post -jsonData '{"name":"test-host"}' | Out-Null

            $script:CapturedBody | Should -Be '{"name":"test-host"}'
        }
    }
}
