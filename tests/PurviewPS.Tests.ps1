#Requires -Module Pester
<#
.SYNOPSIS
    PurviewPS unit test suite.
.DESCRIPTION
    Uses Pester 5+ with mocked Invoke-RestMethod calls so no live Purview
    instance is required.

    Run with:
        Invoke-Pester -Path ./tests -Output Detailed
#>

BeforeAll {
    # Import the module from the source tree
    $modulePath = Join-Path $PSScriptRoot '..' 'PurviewPS' 'PurviewPS.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop

    # A fake connection object with a valid token that satisfies all validation
    $script:MockConn = [PSCustomObject]@{
        PSTypeName   = 'PurviewPS.Connection'
        AccountName  = 'test-purview'
        TenantId     = '00000000-0000-0000-0000-000000000001'
        ClientId     = '00000000-0000-0000-0000-000000000002'
        ClientSecret = 'fake-secret'
        AuthMode     = 'ServicePrincipal'
        AccessToken  = 'fake-token'
        TokenExpiry  = (Get-Date).AddHours(1)
    }

    # Shared test GUIDs
    $script:EntityGuid  = '12345678-0000-0000-0000-000000000001'
    $script:RelGuid     = 'aaaaaaaa-0000-0000-0000-000000000001'
    $script:LineageGuid = 'bbbbbbbb-0000-0000-0000-000000000001'
    $script:GlossaryGuid = 'cccccccc-0000-0000-0000-000000000001'
    $script:TermGuid    = 'dddddddd-0000-0000-0000-000000000001'
}

# ── Connection Management ─────────────────────────────────────────────────────

Describe 'Connection Management' {

    Context 'Connect-Purview (ServicePrincipal)' {

        BeforeAll {
            # Shared Connect-Purview parameters used by every test in this Context
            $script:ConnParams = @{
                AccountName  = 'test-purview'
                TenantId     = '00000000-0000-0000-0000-000000000001'
                ClientId     = '00000000-0000-0000-0000-000000000002'
                ClientSecret = 'secret'
            }
        }

        BeforeEach {
            Mock -ModuleName PurviewPS Invoke-RestMethod {
                return @{
                    access_token = 'mocked-token-123'
                    expires_in   = 3600
                    token_type   = 'Bearer'
                }
            }
            # Clear any existing connection
            InModuleScope PurviewPS { $script:PurviewConnection = $null }
        }

        It 'should store a connection in module scope' {
            Connect-Purview @script:ConnParams

            $conn = Get-PurviewConnection
            $conn | Should -Not -BeNullOrEmpty
            $conn.AccountName | Should -Be 'test-purview'
        }

        It 'should set AccessToken from the token response' {
            Connect-Purview @script:ConnParams

            (Get-PurviewConnection).AccessToken | Should -Be 'mocked-token-123'
        }

        It 'should return the connection when -PassThru is used' {
            $result = Connect-Purview @script:ConnParams -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.TypeNames | Should -Contain 'PurviewPS.Connection'
        }
    }

    Context 'Disconnect-Purview' {

        It 'should clear the active connection' {
            InModuleScope PurviewPS {
                $script:PurviewConnection = [PSCustomObject]@{
                    PSTypeName  = 'PurviewPS.Connection'
                    AccountName = 'test'
                }
            }
            Disconnect-Purview -Confirm:$false
            Get-PurviewConnection | Should -BeNullOrEmpty
        }
    }

    Context 'Test-PurviewConnection' {

        It 'returns $true when connection is valid and token is fresh' {
            $freshConn = [PSCustomObject]@{
                AccessToken = 'valid-token'
                TokenExpiry = (Get-Date).AddHours(1)
            }
            Test-PurviewConnection -Connection $freshConn | Should -BeTrue
        }

        It 'returns $false when no connection is passed and module scope is empty' {
            InModuleScope PurviewPS { $script:PurviewConnection = $null }
            Test-PurviewConnection | Should -BeFalse
        }

        It 'returns $false when token is expired' {
            $expired = [PSCustomObject]@{
                AccessToken = 'old-token'
                TokenExpiry = (Get-Date).AddHours(-1)
            }
            Test-PurviewConnection -Connection $expired | Should -BeFalse
        }
    }
}

# ── Entity ────────────────────────────────────────────────────────────────────

Describe 'Entity API' {

    BeforeAll {
        Mock -ModuleName PurviewPS Invoke-RestMethod { return @{ entity = @{} } }
    }

    Context 'Get-PurviewEntity' {

        It 'calls entity/guid/<guid> for ByGuid set' {
            Get-PurviewEntity -Guid $script:EntityGuid -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like "*/entity/guid/$($script:EntityGuid)*"
            }
        }

        It 'calls entity/guid/<guid>/audit when -Audit is set' {
            Get-PurviewEntity -Guid $script:EntityGuid -Audit -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like "*/entity/guid/$($script:EntityGuid)/audit*"
            }
        }

        It 'calls entity/guid/<guid>/classifications when -Classifications is set' {
            Get-PurviewEntity -Guid $script:EntityGuid -Classifications -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like "*/entity/guid/$($script:EntityGuid)/classifications*"
            }
        }

        It 'calls entity/guid/<guid>/header when -Headers is set' {
            Get-PurviewEntity -Guid $script:EntityGuid -Headers -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like "*/entity/guid/$($script:EntityGuid)/header*"
            }
        }

        It 'calls entity/bulk/headers when Bulk + Headers' {
            Get-PurviewEntity -Guids @($script:EntityGuid) -Headers -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/entity/bulk/headers*'
            }
        }

        It 'calls entity/uniqueAttribute/type/<type> for ByUniqueAttribute set' {
            Get-PurviewEntity -TypeName 'azure_sql_table' -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/entity/uniqueAttribute/type/azure_sql_table*'
            }
        }

        It 'appends qualifiedName query param when -QualifiedName is supplied' {
            Get-PurviewEntity -TypeName 'azure_sql_table' -QualifiedName 'mssql://s/db' -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*qualifiedName*'
            }
        }
    }

    Context 'New-PurviewEntity' {

        It 'POSTs to entity for Single set' {
            New-PurviewEntity -EntityDef @{ entity = @{} } -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/entity' -and $Method -eq 'POST'
            }
        }

        It 'POSTs to entity/bulk for Bulk set' {
            New-PurviewEntity -EntityDef @{ entities = @() } -Bulk -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/entity/bulk' -and $Method -eq 'POST'
            }
        }

        It 'POSTs classifications to entity/guid/<guid>/classifications' {
            New-PurviewEntity -Guid $script:EntityGuid -Classifications `
                -ClassificationDef @( @{ typeName = 'PII' } ) -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like "*/entity/guid/$($script:EntityGuid)/classifications*" -and $Method -eq 'POST'
            }
        }
    }

    Context 'Set-PurviewEntity' {

        It 'PUTs to entity/guid/<guid>' {
            Set-PurviewEntity -Guid $script:EntityGuid -EntityDef @{} -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like "*/entity/guid/$($script:EntityGuid)*" -and $Method -eq 'PUT'
            }
        }
    }

    Context 'Remove-PurviewEntity' {

        It 'DELETEs entity/guid/<guid> for ByGuid set' {
            Remove-PurviewEntity -Guid $script:EntityGuid -Confirm:$false -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like "*/entity/guid/$($script:EntityGuid)*" -and $Method -eq 'DELETE'
            }
        }

        It 'DELETEs classification by name' {
            Remove-PurviewEntity -Guid $script:EntityGuid -ClassificationName 'PII' `
                -Confirm:$false -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like "*/entity/guid/$($script:EntityGuid)/classification/PII*" -and $Method -eq 'DELETE'
            }
        }

        It 'DELETEs by type unique attribute' {
            Remove-PurviewEntity -TypeName 'azure_sql_table' -Confirm:$false -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/entity/uniqueAttribute/type/azure_sql_table*' -and $Method -eq 'DELETE'
            }
        }
    }
}

# ── Type Definitions ──────────────────────────────────────────────────────────

Describe 'TypeDefinition API' {

    BeforeAll {
        Mock -ModuleName PurviewPS Invoke-RestMethod { return @{} }
    }

    Context 'Get-PurviewTypeDefinition' {

        It 'calls types/typedefs for All set' {
            Get-PurviewTypeDefinition -All -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/types/typedefs*'
            }
        }

        It 'calls types/typedefs/headers for Headers set' {
            Get-PurviewTypeDefinition -Headers -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/types/typedefs/headers*'
            }
        }

        It 'calls types/entitydef/name/<name> for ByName + Category Entity' {
            Get-PurviewTypeDefinition -Name 'azure_sql_table' -Category Entity -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/types/entitydef/name/azure_sql_table*'
            }
        }

        It 'calls types/classificationdef/name/<name> for Classification category' {
            Get-PurviewTypeDefinition -Name 'PII' -Category Classification -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/types/classificationdef/name/PII*'
            }
        }

        It 'calls types/typedef/name/<name> when no category' {
            Get-PurviewTypeDefinition -Name 'SomeType' -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/types/typedef/name/SomeType*'
            }
        }
    }

    Context 'New-PurviewTypeDefinition' {

        It 'POSTs to types/typedefs' {
            New-PurviewTypeDefinition -TypeDefs @{} -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/types/typedefs' -and $Method -eq 'POST'
            }
        }
    }

    Context 'Set-PurviewTypeDefinition' {

        It 'PUTs to types/typedefs' {
            Set-PurviewTypeDefinition -TypeDefs @{} -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/types/typedefs' -and $Method -eq 'PUT'
            }
        }
    }

    Context 'Remove-PurviewTypeDefinition' {

        It 'DELETEs types/typedef/name/<name> for ByName set' {
            Remove-PurviewTypeDefinition -Name 'OldType' -Confirm:$false -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/types/typedef/name/OldType*' -and $Method -eq 'DELETE'
            }
        }

        It 'DELETEs types/typedefs for Bulk set' {
            Remove-PurviewTypeDefinition -TypeDefs @{ entityDefs = @() } -Confirm:$false -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/types/typedefs' -and $Method -eq 'DELETE'
            }
        }
    }
}

# ── Relationship ──────────────────────────────────────────────────────────────

Describe 'Relationship API' {

    BeforeAll {
        Mock -ModuleName PurviewPS Invoke-RestMethod { return @{} }
    }

    It 'Get-PurviewRelationship calls relationship/guid/<guid>' {
        Get-PurviewRelationship -Guid $script:RelGuid -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like "*/relationship/guid/$($script:RelGuid)*"
        }
    }

    It 'Get-PurviewRelationship appends extendedInfo param when -ExtendedInfo' {
        Get-PurviewRelationship -Guid $script:RelGuid -ExtendedInfo -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*extendedInfo=true*'
        }
    }

    It 'New-PurviewRelationship POSTs to relationship' {
        New-PurviewRelationship -Relationship @{} -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/relationship' -and $Method -eq 'POST'
        }
    }

    It 'Set-PurviewRelationship PUTs to relationship' {
        Set-PurviewRelationship -Relationship @{} -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/relationship' -and $Method -eq 'PUT'
        }
    }

    It 'Remove-PurviewRelationship DELETEs relationship/guid/<guid>' {
        Remove-PurviewRelationship -Guid $script:RelGuid -Confirm:$false -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like "*/relationship/guid/$($script:RelGuid)*" -and $Method -eq 'DELETE'
        }
    }
}

# ── Lineage ───────────────────────────────────────────────────────────────────

Describe 'Lineage API' {

    BeforeAll {
        Mock -ModuleName PurviewPS Invoke-RestMethod { return @{} }
    }

    It 'Get-PurviewLineage ByGuid calls lineage/{guid}' {
        Get-PurviewLineage -Guid $script:LineageGuid -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/lineage/bbbbbbbb-0000-0000-0000-000000000001*'
        }
    }

    It 'Get-PurviewLineage appends direction and depth query params' {
        Get-PurviewLineage -Guid $script:LineageGuid -Direction INPUT -Depth 5 -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*direction=INPUT*' -and $Uri -like '*depth=5*'
        }
    }

    It 'Get-PurviewLineage ByUniqueAttribute calls lineage/uniqueAttribute/type/{type}' {
        Get-PurviewLineage -TypeName 'azure_sql_table' -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/lineage/uniqueAttribute/type/azure_sql_table*'
        }
    }

    It 'Get-PurviewLineage ByUniqueAttribute encodes qualifiedName' {
        Get-PurviewLineage -TypeName 'azure_sql_table' -QualifiedName 'mssql://s/db' -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*qualifiedName*'
        }
    }
}

# ── Glossary ──────────────────────────────────────────────────────────────────

Describe 'Glossary API' {

    BeforeAll {
        Mock -ModuleName PurviewPS Invoke-RestMethod { return @{} }
    }

    Context 'Get-PurviewGlossary' {

        It 'calls glossary for All set' {
            Get-PurviewGlossary -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/glossary*'
            }
        }

        It 'calls glossary/{guid}/terms when -Terms is set' {
            Get-PurviewGlossary -Guid $script:GlossaryGuid -Terms -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/glossary/cccccccc-0000-0000-0000-000000000001/terms*'
            }
        }

        It 'calls glossary/{guid}/categories when -Categories is set' {
            Get-PurviewGlossary -Guid $script:GlossaryGuid -Categories -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/glossary/cccccccc-0000-0000-0000-000000000001/categories*'
            }
        }

        It 'calls glossary/term/{guid} when -Term is set' {
            Get-PurviewGlossary -Guid $script:TermGuid -Term -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/glossary/term/dddddddd-0000-0000-0000-000000000001*'
            }
        }

        It 'calls glossary/import/template when -ImportTemplate is set' {
            Get-PurviewGlossary -ImportTemplate -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/glossary/import/template*'
            }
        }

        It 'calls glossary/terms/{guid}/assignedEntities for TermAssignedEntities' {
            Get-PurviewGlossary -Guid $script:TermGuid -Term -AssignedEntities -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like "*/glossary/terms/$($script:TermGuid)/assignedEntities*"
            }
        }
    }

    Context 'New-PurviewGlossary' {

        It 'POSTs to glossary for SingleGlossary' {
            New-PurviewGlossary -Glossary @{ name = 'Test' } -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/glossary' -and $Method -eq 'POST'
            }
        }

        It 'POSTs to glossary/term for SingleTerm' {
            New-PurviewGlossary -Term @{ name = 'Revenue' } -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/glossary/term' -and $Method -eq 'POST'
            }
        }

        It 'POSTs to glossary/terms for BulkTerm' {
            New-PurviewGlossary -Terms @( @{ name = 'T1' } ) -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like '*/glossary/terms' -and $Method -eq 'POST'
            }
        }
    }

    Context 'Set-PurviewGlossary' {

        It 'PUTs to glossary/{guid} for Glossary set' {
            Set-PurviewGlossary -Guid $script:GlossaryGuid -Glossary @{} -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like "*/glossary/$($script:GlossaryGuid)*" -and $Method -eq 'PUT'
            }
        }

        It 'PUTs to glossary/term/{guid}/partial when -Partial' {
            Set-PurviewGlossary -Guid $script:TermGuid -Term @{} -Partial -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like "*/glossary/term/$($script:TermGuid)/partial*" -and $Method -eq 'PUT'
            }
        }
    }

    Context 'Remove-PurviewGlossary' {

        It 'DELETEs glossary/{guid} for Glossary set' {
            Remove-PurviewGlossary -Guid $script:GlossaryGuid -Confirm:$false -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like "*/glossary/$($script:GlossaryGuid)*" -and $Method -eq 'DELETE'
            }
        }

        It 'DELETEs glossary/term/{guid} for Term set' {
            Remove-PurviewGlossary -Guid $script:TermGuid -Term -Confirm:$false -Connection $script:MockConn
            Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
                $Uri -like "*/glossary/term/$($script:TermGuid)*" -and $Method -eq 'DELETE'
            }
        }
    }
}

# ── Search ────────────────────────────────────────────────────────────────────

Describe 'Search API' {

    BeforeAll {
        Mock -ModuleName PurviewPS Invoke-RestMethod { return @{ value = @() } }
    }

    It 'Search-Purview POSTs to search/query for SearchRequest' {
        Search-Purview -SearchRequest @{ keywords = 'test'; limit = 10 } -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/search/query*' -and $Method -eq 'POST'
        }
    }

    It 'Search-Purview POSTs to search/suggest for SuggestRequest' {
        Search-Purview -SuggestRequest @{ keywords = 'rev'; limit = 5 } -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/search/suggest*' -and $Method -eq 'POST'
        }
    }

    It 'Search-Purview POSTs to search/autocomplete for AutoCompleteRequest' {
        Search-Purview -AutoCompleteRequest @{ keyword = 'cust'; limit = 10 } -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/search/autocomplete*' -and $Method -eq 'POST'
        }
    }
}

# ── Scanning ──────────────────────────────────────────────────────────────────

Describe 'Scanning API' {

    BeforeAll {
        Mock -ModuleName PurviewPS Invoke-RestMethod { return @{ value = @() } }
    }

    It 'Get-PurviewDataSource lists all data sources' {
        Get-PurviewDataSource -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/scan/datasources*'
        }
    }

    It 'Get-PurviewDataSource retrieves single source by name' {
        Get-PurviewDataSource -Name 'MyDB' -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/scan/datasources/MyDB*'
        }
    }

    It 'New-PurviewDataSource PUTs datasources/<name>' {
        New-PurviewDataSource -Name 'NewDB' -DataSourceDef @{ kind = 'AzureSqlDatabase' } -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/datasources/NewDB*' -and $Method -eq 'PUT'
        }
    }

    It 'Remove-PurviewDataSource DELETEs datasources/<name>' {
        Remove-PurviewDataSource -Name 'OldDB' -Confirm:$false -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/datasources/OldDB*' -and $Method -eq 'DELETE'
        }
    }

    It 'Get-PurviewScan lists scans for a data source' {
        Get-PurviewScan -DataSourceName 'MyDB' -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/datasources/MyDB/scans*'
        }
    }

    It 'Get-PurviewScan retrieves specific scan' {
        Get-PurviewScan -DataSourceName 'MyDB' -ScanName 'FullScan' -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/datasources/MyDB/scans/FullScan*'
        }
    }

    It 'New-PurviewScan PUTs datasources/<ds>/scans/<scan>' {
        New-PurviewScan -DataSourceName 'MyDB' -ScanName 'FullScan' -ScanDef @{ kind = 'AzureSqlDatabaseMsi' } -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/datasources/MyDB/scans/FullScan*' -and $Method -eq 'PUT'
        }
    }

    It 'Set-PurviewScan PUTs datasources/<ds>/scans/<scan>' {
        Set-PurviewScan -DataSourceName 'MyDB' -ScanName 'FullScan' -ScanDef @{ kind = 'AzureSqlDatabaseMsi' } -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/datasources/MyDB/scans/FullScan*' -and $Method -eq 'PUT'
        }
    }

    It 'Remove-PurviewScan DELETEs datasources/<ds>/scans/<scan>' {
        Remove-PurviewScan -DataSourceName 'MyDB' -ScanName 'FullScan' -Confirm:$false -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/datasources/MyDB/scans/FullScan*' -and $Method -eq 'DELETE'
        }
    }

    It 'Start-PurviewScan POSTs to runs/<runId>' {
        Start-PurviewScan -DataSourceName 'MyDB' -ScanName 'FullScan' -Confirm:$false -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/datasources/MyDB/scans/FullScan/runs/*' -and $Method -eq 'POST'
        }
    }

    It 'Stop-PurviewScan POSTs to runs/<id>/:cancel' {
        Stop-PurviewScan -DataSourceName 'MyDB' -ScanName 'FullScan' -RunId 'run-001' -Confirm:$false -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/runs/run-001/:cancel*' -and $Method -eq 'POST'
        }
    }

    It 'Get-PurviewScanRun lists run history' {
        Get-PurviewScanRun -DataSourceName 'MyDB' -ScanName 'FullScan' -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/scans/FullScan/runs*'
        }
    }

    It 'Get-PurviewScanTrigger calls triggers/default' {
        Get-PurviewScanTrigger -DataSourceName 'MyDB' -ScanName 'FullScan' -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/triggers/default*'
        }
    }

    It 'Set-PurviewScanTrigger PUTs triggers/default' {
        Set-PurviewScanTrigger -DataSourceName 'MyDB' -ScanName 'FullScan' -TriggerDef @{} -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/triggers/default*' -and $Method -eq 'PUT'
        }
    }

    It 'Remove-PurviewScanTrigger DELETEs triggers/default' {
        Remove-PurviewScanTrigger -DataSourceName 'MyDB' -ScanName 'FullScan' -Confirm:$false -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/triggers/default*' -and $Method -eq 'DELETE'
        }
    }

    It 'Get-PurviewScanFilter calls filters/custom' {
        Get-PurviewScanFilter -DataSourceName 'MyDB' -ScanName 'FullScan' -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/filters/custom*'
        }
    }

    It 'Set-PurviewScanFilter PUTs filters/custom' {
        Set-PurviewScanFilter -DataSourceName 'MyDB' -ScanName 'FullScan' -FilterDef @{} -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/filters/custom*' -and $Method -eq 'PUT'
        }
    }
}

# ── Collections ───────────────────────────────────────────────────────────────

Describe 'Collections API' {

    BeforeAll {
        Mock -ModuleName PurviewPS Invoke-RestMethod { return @{ value = @() } }
    }

    It 'Get-PurviewCollection lists all collections' {
        Get-PurviewCollection -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/account/collections*'
        }
    }

    It 'Get-PurviewCollection retrieves single collection' {
        Get-PurviewCollection -Name 'finance' -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/collections/finance*'
        }
    }

    It 'Get-PurviewCollection -ChildNames calls childcollectionnames' {
        Get-PurviewCollection -Name 'finance' -ChildNames -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/collections/finance/childcollectionnames*'
        }
    }

    It 'New-PurviewCollection PUTs collections/<name>' {
        New-PurviewCollection -Name 'finance' -CollectionDef @{ friendlyName = 'Finance' } -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/collections/finance*' -and $Method -eq 'PUT'
        }
    }

    It 'Move-PurviewCollectionResource POSTs to moveresources' {
        Move-PurviewCollectionResource -CollectionName 'finance' -ResourceIds @('id1') -Confirm:$false -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/collections/finance/moveresources*' -and $Method -eq 'POST'
        }
    }

    It 'Remove-PurviewCollection DELETEs collections/<name>' {
        Remove-PurviewCollection -Name 'old-col' -Confirm:$false -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/collections/old-col*' -and $Method -eq 'DELETE'
        }
    }
}

# ── Metadata Policy ───────────────────────────────────────────────────────────

Describe 'Metadata Policy API' {

    BeforeAll {
        Mock -ModuleName PurviewPS Invoke-RestMethod { return @{ values = @() } }
    }

    It 'Get-PurviewMetadataPolicy lists all policies' {
        Get-PurviewMetadataPolicy -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/metadataPolicies*'
        }
    }

    It 'Get-PurviewMetadataPolicy filters by collection name' {
        Get-PurviewMetadataPolicy -CollectionName 'finance' -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*collectionName=finance*'
        }
    }

    It 'Get-PurviewMetadataPolicy retrieves policy by ID' {
        Get-PurviewMetadataPolicy -PolicyId 'pol-001' -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/metadataPolicies/pol-001*'
        }
    }

    It 'Set-PurviewMetadataPolicy PUTs to metadataPolicies/<id>' {
        Set-PurviewMetadataPolicy -PolicyId 'pol-001' -PolicyDef @{ name = 'Updated' } -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/metadataPolicies/pol-001*' -and $Method -eq 'PUT'
        }
    }

    It 'Get-PurviewMetadataRole calls metadataRoles' {
        Get-PurviewMetadataRole -Connection $script:MockConn
        Should -Invoke Invoke-RestMethod -ModuleName PurviewPS -ParameterFilter {
            $Uri -like '*/metadataRoles*'
        }
    }
}

# ── Private Helpers ───────────────────────────────────────────────────────────

Describe 'Private: Get-PurviewConnectionOrThrow' {

    It 'returns the supplied connection when provided' {
        InModuleScope PurviewPS {
            $conn   = [PSCustomObject]@{ AccountName = 'test' }
            $result = Get-PurviewConnectionOrThrow -Connection $conn
            $result.AccountName | Should -Be 'test'
        }
    }

    It 'returns module-scope connection when no param is supplied' {
        InModuleScope PurviewPS {
            $script:PurviewConnection = [PSCustomObject]@{ AccountName = 'module-conn' }
            $result = Get-PurviewConnectionOrThrow -Connection $null
            $result.AccountName | Should -Be 'module-conn'
        }
    }

    It 'throws when neither param nor module-scope connection exists' {
        InModuleScope PurviewPS {
            $script:PurviewConnection = $null
            { Get-PurviewConnectionOrThrow -Connection $null } | Should -Throw
        }
    }
}

Describe 'Private: Invoke-PurviewRequest URL construction' {

    It 'builds correct Atlas catalog URL' {
        InModuleScope PurviewPS {
            $conn = [PSCustomObject]@{
                AccountName = 'test-purview'; AccessToken = 'tok'
                TokenExpiry = (Get-Date).AddHours(1)
            }
            Mock Invoke-RestMethod { return @{} }
            Invoke-PurviewRequest -Resource 'entity/bulk' -ApiType Atlas -Connection $conn
            Should -Invoke Invoke-RestMethod -ParameterFilter {
                $Uri -eq 'https://test-purview.purview.azure.com/catalog/api/atlas/v2/entity/bulk'
            }
        }
    }

    It 'builds correct Scan URL with api-version query param' {
        InModuleScope PurviewPS {
            $conn = [PSCustomObject]@{
                AccountName = 'test-purview'; AccessToken = 'tok'
                TokenExpiry = (Get-Date).AddHours(1)
            }
            Mock Invoke-RestMethod { return @{} }
            Invoke-PurviewRequest -Resource 'datasources' -ApiType Scan -Connection $conn
            Should -Invoke Invoke-RestMethod -ParameterFilter {
                $Uri -like '*purview.azure.com/scan/datasources?api-version=*'
            }
        }
    }

    It 'builds correct Account URL with api-version query param' {
        InModuleScope PurviewPS {
            $conn = [PSCustomObject]@{
                AccountName = 'test-purview'; AccessToken = 'tok'
                TokenExpiry = (Get-Date).AddHours(1)
            }
            Mock Invoke-RestMethod { return @{} }
            Invoke-PurviewRequest -Resource 'collections' -ApiType Account -Connection $conn
            Should -Invoke Invoke-RestMethod -ParameterFilter {
                $Uri -like '*purview.azure.com/account/collections?api-version=*'
            }
        }
    }
}

# ── Backward-Compatibility Aliases ────────────────────────────────────────────

Describe 'Backward-Compatibility Aliases' {

    It 'New-Search is an alias for Search-Purview' {
        (Get-Alias 'New-Search').ResolvedCommandName | Should -Be 'Search-Purview'
    }

    It 'Get-Entity is an alias for Get-PurviewEntity' {
        (Get-Alias 'Get-Entity').ResolvedCommandName | Should -Be 'Get-PurviewEntity'
    }

    It 'Add-Entity is an alias for New-PurviewEntity' {
        (Get-Alias 'Add-Entity').ResolvedCommandName | Should -Be 'New-PurviewEntity'
    }

    It 'Get-Glossary is an alias for Get-PurviewGlossary' {
        (Get-Alias 'Get-Glossary').ResolvedCommandName | Should -Be 'Get-PurviewGlossary'
    }

    It 'Get-Lineage is an alias for Get-PurviewLineage' {
        (Get-Alias 'Get-Lineage').ResolvedCommandName | Should -Be 'Get-PurviewLineage'
    }

    It 'Get-TypeDefs is an alias for Get-PurviewTypeDefinition' {
        (Get-Alias 'Get-TypeDefs').ResolvedCommandName | Should -Be 'Get-PurviewTypeDefinition'
    }

    It 'New-PurviewClient is an alias for Connect-Purview' {
        (Get-Alias 'New-PurviewClient').ResolvedCommandName | Should -Be 'Connect-Purview'
    }
}
