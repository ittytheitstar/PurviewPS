#
# Module manifest for PurviewPS
#

@{
    # Module Identity
    RootModule        = 'PurviewPS.psm1'
    ModuleVersion     = '2.0.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'PurviewPS Contributors'
    CompanyName       = ''
    Copyright         = '(c) PurviewPS Contributors. All rights reserved.'
    Description       = 'A PowerShell module for interacting with Microsoft Purview ' +
                        'via its REST APIs: Data Map (Atlas v2), Scanning, Collections, ' +
                        'Metadata Policy, and Search/Discovery.'

    # Minimum PowerShell version
    PowerShellVersion = '5.1'

    # Exported functions (all Public/*.ps1 file names without extension)
    FunctionsToExport = @(
        # Connection
        'Connect-Purview'
        'Disconnect-Purview'
        'Get-PurviewConnection'
        'Test-PurviewConnection'

        # Entity
        'Get-PurviewEntity'
        'New-PurviewEntity'
        'Set-PurviewEntity'
        'Remove-PurviewEntity'

        # Type Definitions
        'Get-PurviewTypeDefinition'
        'New-PurviewTypeDefinition'
        'Set-PurviewTypeDefinition'
        'Remove-PurviewTypeDefinition'

        # Relationship
        'Get-PurviewRelationship'
        'New-PurviewRelationship'
        'Set-PurviewRelationship'
        'Remove-PurviewRelationship'

        # Lineage
        'Get-PurviewLineage'

        # Glossary
        'Get-PurviewGlossary'
        'New-PurviewGlossary'
        'Set-PurviewGlossary'
        'Remove-PurviewGlossary'

        # Search / Discovery
        'Search-Purview'

        # Scanning
        'Get-PurviewDataSource'
        'New-PurviewDataSource'
        'Remove-PurviewDataSource'
        'Get-PurviewScan'
        'New-PurviewScan'
        'Set-PurviewScan'
        'Remove-PurviewScan'
        'Start-PurviewScan'
        'Stop-PurviewScan'
        'Get-PurviewScanRun'
        'Get-PurviewScanFilter'
        'Set-PurviewScanFilter'
        'Get-PurviewScanTrigger'
        'Set-PurviewScanTrigger'
        'Remove-PurviewScanTrigger'

        # Collections
        'Get-PurviewCollection'
        'New-PurviewCollection'
        'Set-PurviewCollection'
        'Remove-PurviewCollection'
        'Move-PurviewCollectionResource'

        # Metadata Policy
        'Get-PurviewMetadataPolicy'
        'Set-PurviewMetadataPolicy'
        'Get-PurviewMetadataRole'
    )

    # Backward-compatibility aliases
    AliasesToExport = @(
        'New-PurviewClient'
        'Get-Entity'
        'Add-Entity'
        'Set-Entity'
        'Remove-Entity'
        'Get-TypeDefs'
        'Add-TypeDefs'
        'Set-TypeDefs'
        'Remove-TypeDefs'
        'Get-Relationship'
        'Add-Relationship'
        'Set-Relationship'
        'Remove-Relationship'
        'Get-Lineage'
        'Get-Glossary'
        'Add-Glossary'
        'Set-Glossary'
        'Remove-Glossary'
        'New-Search'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()

    # Private data / PSData block for PowerShell Gallery
    PrivateData = @{
        PSData = @{
            Tags         = @('Purview', 'Azure', 'DataGovernance', 'Atlas', 'DataCatalog', 'Microsoft')
            LicenseUri   = 'https://github.com/ittytheitstar/PurviewPS/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/ittytheitstar/PurviewPS'
            ReleaseNotes = @'
## 2.0.0
- Full module refactor into multi-file structure (Public/Private split)
- Global connection state via Connect-Purview / Disconnect-Purview
- Managed Identity authentication support
- New Scanning API: data sources, scans, runs, triggers, filters
- New Collections API: CRUD + move resources
- New Metadata Policy API: policies and roles
- Improved Search API using POST search/query endpoint
- Fixed token comparison bugs (== -> -eq)
- Fixed URL construction bugs in Lineage and Glossary
- Proper SupportsShouldProcess on all Remove-* functions
- Backward-compatible aliases for all v1 function names
'@
        }
    }
}
