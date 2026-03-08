# PurviewPS

A comprehensive PowerShell module for interacting with **Microsoft Purview** via its REST APIs.

[![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://github.com/PowerShell/PowerShell)

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Authentication](#authentication)
5. [Quick Start](#quick-start)
6. [Command Reference](#command-reference)
   - [Connection](#connection)
   - [Entity](#entity)
   - [Type Definitions](#type-definitions)
   - [Relationship](#relationship)
   - [Lineage](#lineage)
   - [Glossary](#glossary)
   - [Search / Discovery](#search--discovery)
   - [Scanning](#scanning)
   - [Collections](#collections)
   - [Metadata Policy](#metadata-policy)
7. [Data Dictionary](#data-dictionary)
8. [Examples](#examples)
9. [Running the Tests](#running-the-tests)
10. [Backward Compatibility](#backward-compatibility)
11. [Module Structure](#module-structure)

---

## Overview

PurviewPS wraps Microsoft Purview's REST APIs into PowerShell-idiomatic cmdlets:

| API Surface          | Base URL pattern                                              |
|----------------------|---------------------------------------------------------------|
| Data Map (Atlas v2)  | `https://<account>.purview.azure.com/catalog/api/atlas/v2`   |
| Scanning             | `https://<account>.purview.azure.com/scan`                   |
| Collections          | `https://<account>.purview.azure.com/account`                |
| Metadata Policy      | `https://<account>.purview.azure.com/policystore`            |

---

## Prerequisites

- PowerShell 5.1 or PowerShell 7+
- A provisioned [Microsoft Purview account](https://docs.microsoft.com/azure/purview/create-catalog-portal)
- One of:
  - An **App Registration** (Service Principal) with a Client Secret, granted the *Purview Data Curator* or *Purview Data Reader* role
  - A **Managed Identity** assigned to the resource running this module

---

## Installation

```powershell
# From the cloned repository
Import-Module .\PurviewPS\PurviewPS.psd1 -Force

# Verify
Get-Module PurviewPS
```

---

## Authentication

### Service Principal (recommended for automation)

```powershell
Connect-Purview `
    -AccountName  'contoso-purview' `
    -TenantId     '00000000-0000-0000-0000-000000000000' `
    -ClientId     '00000000-0000-0000-0000-000000000000' `
    -ClientSecret 'your-client-secret'
```

### Managed Identity (inside Azure – no secrets required)

```powershell
# System-Assigned Managed Identity
Connect-Purview -AccountName 'contoso-purview' -ManagedIdentity

# User-Assigned Managed Identity
Connect-Purview -AccountName 'contoso-purview' -ManagedIdentity `
    -ManagedIdentityClientId '00000000-0000-0000-0000-000000000000'
```

### Multi-account scenarios

Use `-PassThru` to capture the connection object and pass it explicitly:

```powershell
$dev  = Connect-Purview -AccountName 'dev-purview'  ... -PassThru
$prod = Connect-Purview -AccountName 'prod-purview' ... -PassThru

Get-PurviewEntity -Guid $id -Connection $dev
Get-PurviewEntity -Guid $id -Connection $prod
```

### Checking / clearing the connection

```powershell
Test-PurviewConnection          # returns $true / $false
Get-PurviewConnection           # returns the active connection object
Disconnect-Purview              # clears the active connection
```

---

## Quick Start

```powershell
# 1. Connect
Connect-Purview -AccountName 'contoso-purview' `
    -TenantId '...' -ClientId '...' -ClientSecret '...'

# 2. Search for assets
$results = Search-Purview -SearchRequest @{ keywords = 'customer'; limit = 25 }
$results.value | Select-Object name, entityType, qualifiedName

# 3. Get a specific entity
$entity = Get-PurviewEntity -Guid 'abc12345-...'

# 4. List glossary terms
Get-PurviewGlossary -All | Select-Object -ExpandProperty terms
```

---

## Command Reference

### Connection

| Command                  | Description                                          |
|--------------------------|------------------------------------------------------|
| `Connect-Purview`        | Authenticate and store an active connection          |
| `Disconnect-Purview`     | Clear the active connection                          |
| `Get-PurviewConnection`  | Return the active connection object                  |
| `Test-PurviewConnection` | Check if a connection is active and token is valid   |

---

### Entity

| Command               | HTTP   | Endpoint                                                     |
|-----------------------|--------|--------------------------------------------------------------|
| `Get-PurviewEntity`   | GET    | `entity/guid/{guid}`, `entity/bulk`, `entity/uniqueAttribute/type/{type}` |
| `New-PurviewEntity`   | POST   | `entity`, `entity/bulk`, `entity/guid/{guid}/classifications`, … |
| `Set-PurviewEntity`   | PUT    | `entity/guid/{guid}`, `entity/guid/{guid}/classifications`, … |
| `Remove-PurviewEntity`| DELETE | `entity/guid/{guid}`, `entity/bulk`, `entity/guid/{guid}/classification/{name}`, … |

**Key parameters for `Get-PurviewEntity`:**

| Parameter              | Type     | Description                                        |
|------------------------|----------|----------------------------------------------------|
| `-Guid`                | string   | Entity GUID                                        |
| `-Guids`               | string[] | Multiple GUIDs (bulk)                              |
| `-TypeName`            | string   | Entity type for unique-attribute lookup            |
| `-QualifiedName`       | string   | qualifiedName attribute value                      |
| `-Headers`             | switch   | Return header-only payload                         |
| `-Classifications`     | switch   | Return classifications on the entity               |
| `-ClassificationName`  | string   | Return a single named classification               |
| `-Audit`               | switch   | Return audit history                               |
| `-MinExtInfo`          | switch   | Exclude referred entities from response            |
| `-IgnoreRelationships` | switch   | Exclude relationship attributes                    |

---

### Type Definitions

| Command                      | HTTP   | Endpoint                                             |
|------------------------------|--------|------------------------------------------------------|
| `Get-PurviewTypeDefinition`  | GET    | `types/typedefs`, `types/typedef/name/{name}`, `types/{cat}def/guid/{guid}` |
| `New-PurviewTypeDefinition`  | POST   | `types/typedefs`                                     |
| `Set-PurviewTypeDefinition`  | PUT    | `types/typedefs`                                     |
| `Remove-PurviewTypeDefinition` | DELETE | `types/typedef/name/{name}`, `types/typedefs`      |

**Category values:** `BusinessMetadata` | `Classification` | `Entity` | `Enum` | `Relationship` | `Struct`

---

### Relationship

| Command                   | HTTP   | Endpoint                      |
|---------------------------|--------|-------------------------------|
| `Get-PurviewRelationship` | GET    | `relationship/guid/{guid}`    |
| `New-PurviewRelationship` | POST   | `relationship`                |
| `Set-PurviewRelationship` | PUT    | `relationship`                |
| `Remove-PurviewRelationship` | DELETE | `relationship/guid/{guid}` |

---

### Lineage

| Command              | HTTP | Endpoint                                                    |
|----------------------|------|-------------------------------------------------------------|
| `Get-PurviewLineage` | GET  | `lineage/{guid}`, `lineage/uniqueAttribute/type/{typeName}` |

**Parameters:** `-Direction` (INPUT/OUTPUT/BOTH), `-Depth` (1-25), `-Width` (1-25)

---

### Glossary

| Command               | HTTP   | Endpoint                                                      |
|-----------------------|--------|---------------------------------------------------------------|
| `Get-PurviewGlossary` | GET    | `glossary`, `glossary/{guid}`, `glossary/term/{guid}`, …     |
| `New-PurviewGlossary` | POST   | `glossary`, `glossary/term`, `glossary/terms`, …             |
| `Set-PurviewGlossary` | PUT    | `glossary/{guid}`, `glossary/term/{guid}/partial`, …         |
| `Remove-PurviewGlossary` | DELETE | `glossary/{guid}`, `glossary/term/{guid}`, …              |

---

### Search / Discovery

| Command         | HTTP | Endpoint               |
|-----------------|------|------------------------|
| `Search-Purview`| POST | `search/query`         |
| `Search-Purview`| POST | `search/suggest`       |
| `Search-Purview`| POST | `search/autocomplete`  |

```powershell
# Advanced search
Search-Purview -SearchRequest @{
    keywords = 'revenue'
    limit    = 25
    filter   = @{ entityType = 'azure_sql_table' }
    facets   = @( @{ field = 'entityType'; sort = 'count'; count = 5 } )
}

# Suggest
Search-Purview -SuggestRequest @{ keywords = 'rev'; limit = 5 }

# Autocomplete
Search-Purview -AutoCompleteRequest @{ keyword = 'cust'; limit = 10 }
```

---

### Scanning

| Command                   | HTTP   | Endpoint                                                   |
|---------------------------|--------|------------------------------------------------------------|
| `Get-PurviewDataSource`   | GET    | `datasources`, `datasources/{name}`                        |
| `New-PurviewDataSource`   | PUT    | `datasources/{name}`                                       |
| `Remove-PurviewDataSource`| DELETE | `datasources/{name}`                                       |
| `Get-PurviewScan`         | GET    | `datasources/{ds}/scans`, `datasources/{ds}/scans/{scan}`  |
| `New-PurviewScan`         | PUT    | `datasources/{ds}/scans/{scan}`                            |
| `Remove-PurviewScan`      | DELETE | `datasources/{ds}/scans/{scan}`                            |
| `Start-PurviewScan`       | POST   | `datasources/{ds}/scans/{scan}/runs/{runId}`               |
| `Stop-PurviewScan`        | POST   | `datasources/{ds}/scans/{scan}/runs/{runId}/:cancel`       |
| `Get-PurviewScanRun`      | GET    | `datasources/{ds}/scans/{scan}/runs`                       |
| `Get-PurviewScanFilter`   | GET    | `datasources/{ds}/scans/{scan}/filters/custom`             |
| `Set-PurviewScanFilter`   | PUT    | `datasources/{ds}/scans/{scan}/filters/custom`             |
| `Get-PurviewScanTrigger`  | GET    | `datasources/{ds}/scans/{scan}/triggers/default`           |
| `Set-PurviewScanTrigger`  | PUT    | `datasources/{ds}/scans/{scan}/triggers/default`           |
| `Remove-PurviewScanTrigger` | DELETE | `datasources/{ds}/scans/{scan}/triggers/default`         |

---

### Collections

| Command                        | HTTP   | Endpoint                                      |
|--------------------------------|--------|-----------------------------------------------|
| `Get-PurviewCollection`        | GET    | `collections`, `collections/{name}`           |
| `New-PurviewCollection`        | PUT    | `collections/{name}`                          |
| `Set-PurviewCollection`        | PUT    | `collections/{name}`                          |
| `Remove-PurviewCollection`     | DELETE | `collections/{name}`                          |
| `Move-PurviewCollectionResource` | POST | `collections/{name}/moveresources`            |

---

### Metadata Policy

| Command                   | HTTP | Endpoint                                          |
|---------------------------|------|---------------------------------------------------|
| `Get-PurviewMetadataPolicy` | GET | `metadataPolicies`, `metadataPolicies/{id}`       |
| `Set-PurviewMetadataPolicy` | PUT | `metadataPolicies/{id}`                           |
| `Get-PurviewMetadataRole`  | GET | `metadataRoles`                                   |

---

## Data Dictionary

### Connection Object (`PurviewPS.Connection`)

| Property      | Type     | Description                                              |
|---------------|----------|----------------------------------------------------------|
| AccountName   | string   | Purview account name                                     |
| TenantId      | string   | AAD tenant GUID (ServicePrincipal only)                  |
| ClientId      | string   | App Registration / User-Assigned MI client GUID          |
| ClientSecret  | string   | Client secret (ServicePrincipal only)                    |
| AuthMode      | string   | `ServicePrincipal` or `ManagedIdentity`                  |
| AccessToken   | string   | Current bearer token (managed automatically)             |
| TokenExpiry   | DateTime | Expiry time of the current token                         |

### AtlasEntity

| Property               | Type                         | Description                         |
|------------------------|------------------------------|-------------------------------------|
| guid                   | string                       | Unique entity GUID                  |
| typeName               | string                       | Atlas type name                     |
| attributes             | hashtable                    | Type-specific attribute values      |
| status                 | string                       | ACTIVE or DELETED                   |
| classifications        | AtlasClassification[]        | Applied classifications             |
| meanings               | AtlasTermAssignmentHeader[]  | Linked glossary terms               |
| relationshipAttributes | hashtable                    | Related entity references           |
| contacts               | hashtable                    | Experts and Owners                  |
| labels                 | hashtable                    | User-defined labels                 |
| createTime             | long                         | Creation Unix timestamp             |
| updateTime             | long                         | Last update Unix timestamp          |

### AtlasGlossaryTerm

| Property         | Type                          | Description                                   |
|------------------|-------------------------------|-----------------------------------------------|
| guid             | string                        | Term GUID                                     |
| name             | string                        | Term name                                     |
| qualifiedName    | string                        | Unique qualified name                         |
| anchor           | AtlasGlossaryHeader           | Parent glossary reference                     |
| status           | string                        | Draft, Approved, Alert, or Expired            |
| assignedEntities | AtlasRelatedObjectId[]        | Entities this term is assigned to             |
| synonyms         | AtlasRelatedTermHeader[]      | Synonym terms                                 |
| antonyms         | AtlasRelatedTermHeader[]      | Antonym terms                                 |
| resources        | ResourceLink[]                | External resource links                       |

### SearchRequest

| Property        | Type         | Description                                              |
|-----------------|--------------|----------------------------------------------------------|
| keywords        | string       | Free-text search string                                  |
| offset          | int          | Pagination offset                                        |
| limit           | int          | Max results to return                                    |
| filter          | hashtable    | OData-style filter expression                            |
| facets          | hashtable[]  | Aggregation facet definitions                            |

---

## Examples

### Create and tag an entity

```powershell
Connect-Purview -AccountName 'contoso-purview' ...

# Create entity
$entity = @{
    entity = @{
        typeName   = 'DataSet'
        attributes = @{
            qualifiedName = 'custom://my-dataset'
            name          = 'MyDataset'
            description   = 'Example dataset'
        }
    }
}
$result = New-PurviewEntity -EntityDef $entity
$guid = $result.guidAssignments.Values | Select-Object -First 1

# Apply a classification
New-PurviewEntity -Guid $guid -Classifications `
    -ClassificationDef @( @{ typeName = 'PII' } )

# Assign a glossary term
$rel = @{
    typeName = 'AtlasGlossarySemanticAssignment'
    end1     = @{ guid = $termGuid;  typeName = 'AtlasGlossaryTerm' }
    end2     = @{ guid = $guid;      typeName = 'DataSet' }
}
New-PurviewRelationship -Relationship $rel
```

### Register a data source and run a scan

```powershell
# Register Azure SQL Database
$ds = @{
    kind       = 'AzureSqlDatabase'
    properties = @{
        serverEndpoint = 'myserver.database.windows.net'
        collection     = @{ referenceName = 'root'; type = 'CollectionReference' }
    }
}
New-PurviewDataSource -Name 'SqlFinance' -DataSourceDef $ds

# Create a scan
$scan = @{
    kind       = 'AzureSqlDatabaseMsi'
    properties = @{
        databaseName    = 'FinanceDB'
        scanRulesetName = 'AzureSqlDatabase'
        scanRulesetType = 'System'
        collection      = @{ referenceName = 'root'; type = 'CollectionReference' }
    }
}
New-PurviewScan -DataSourceName 'SqlFinance' -ScanName 'FullScan' -ScanDef $scan

# Run it
Start-PurviewScan -DataSourceName 'SqlFinance' -ScanName 'FullScan'

# Check run history
Get-PurviewScanRun -DataSourceName 'SqlFinance' -ScanName 'FullScan'
```

### Manage collections

```powershell
# Create a child collection
New-PurviewCollection -Name 'finance' -CollectionDef @{
    friendlyName     = 'Finance'
    parentCollection = @{ referenceName = 'root' }
    description      = 'Finance department assets'
}

# Move assets into it
$guids = (Search-Purview -SearchRequest @{ keywords = 'finance'; limit = 100 }).value.id
Move-PurviewCollectionResource -CollectionName 'finance' -ResourceIds $guids
```

### Grant access via Metadata Policy

```powershell
# Get the current policy for a collection
$policy = Get-PurviewMetadataPolicy -CollectionName 'finance'

# View available roles
Get-PurviewMetadataRole | Select-Object id, friendlyName

# Update the policy (add a user to the Data Curator role)
# ... modify $policy.properties.attributeRules as per API schema ...
Set-PurviewMetadataPolicy -PolicyId $policy.id -PolicyDef $policy
```

---

## Running the Tests

Requires [Pester 5+](https://pester.dev/docs/introduction/installation):

```powershell
Install-Module Pester -Force -SkipPublisherCheck
Invoke-Pester -Path ./tests -Output Detailed
```

All tests use mocked HTTP calls – no live Purview instance is needed.

---

## Backward Compatibility

All v1 function names are aliased to their v2 equivalents:

| Old name            | New name                        |
|---------------------|---------------------------------|
| `New-PurviewClient` | `Connect-Purview`               |
| `Get-Entity`        | `Get-PurviewEntity`             |
| `Add-Entity`        | `New-PurviewEntity`             |
| `Set-Entity`        | `Set-PurviewEntity`             |
| `Remove-Entity`     | `Remove-PurviewEntity`          |
| `Get-TypeDefs`      | `Get-PurviewTypeDefinition`     |
| `Add-TypeDefs`      | `New-PurviewTypeDefinition`     |
| `Set-TypeDefs`      | `Set-PurviewTypeDefinition`     |
| `Remove-TypeDefs`   | `Remove-PurviewTypeDefinition`  |
| `Get-Relationship`  | `Get-PurviewRelationship`       |
| `Add-Relationship`  | `New-PurviewRelationship`       |
| `Set-Relationship`  | `Set-PurviewRelationship`       |
| `Remove-Relationship` | `Remove-PurviewRelationship`  |
| `Get-Lineage`       | `Get-PurviewLineage`            |
| `Get-Glossary`      | `Get-PurviewGlossary`           |
| `Add-Glossary`      | `New-PurviewGlossary`           |
| `Set-Glossary`      | `Set-PurviewGlossary`           |
| `Remove-Glossary`   | `Remove-PurviewGlossary`        |
| `New-Search`        | `Search-Purview`                |

---

## Module Structure

```
PurviewPS/
├── PurviewPS.psd1              Module manifest
├── PurviewPS.psm1              Root: class definitions + dot-source loader
├── Private/
│   ├── Get-PurviewConnectionOrThrow.ps1   Internal: connection resolver
│   ├── Invoke-PurviewRequest.ps1          Internal: HTTP dispatcher
│   └── Update-PurviewToken.ps1            Internal: OAuth token refresh
└── Public/
    ├── Connection/
    │   ├── Connect-Purview.ps1
    │   ├── Disconnect-Purview.ps1
    │   ├── Get-PurviewConnection.ps1
    │   └── Test-PurviewConnection.ps1
    ├── Entity/
    │   ├── Get-PurviewEntity.ps1
    │   ├── New-PurviewEntity.ps1
    │   ├── Set-PurviewEntity.ps1
    │   └── Remove-PurviewEntity.ps1
    ├── TypeDefs/
    │   ├── Get-PurviewTypeDefinition.ps1
    │   ├── New-PurviewTypeDefinition.ps1
    │   ├── Set-PurviewTypeDefinition.ps1
    │   └── Remove-PurviewTypeDefinition.ps1
    ├── Relationship/
    │   ├── Get-PurviewRelationship.ps1
    │   ├── New-PurviewRelationship.ps1
    │   ├── Set-PurviewRelationship.ps1
    │   └── Remove-PurviewRelationship.ps1
    ├── Lineage/
    │   └── Get-PurviewLineage.ps1
    ├── Glossary/
    │   ├── Get-PurviewGlossary.ps1
    │   ├── New-PurviewGlossary.ps1
    │   ├── Set-PurviewGlossary.ps1
    │   └── Remove-PurviewGlossary.ps1
    ├── Search/
    │   └── Search-Purview.ps1
    ├── Scan/
    │   ├── Get-PurviewDataSource.ps1
    │   ├── New-PurviewDataSource.ps1
    │   ├── Remove-PurviewDataSource.ps1
    │   ├── Get-PurviewScan.ps1
    │   ├── New-PurviewScan.ps1
    │   ├── Remove-PurviewScan.ps1
    │   ├── Start-PurviewScan.ps1
    │   ├── Stop-PurviewScan.ps1
    │   ├── Get-PurviewScanRun.ps1
    │   ├── Get-PurviewScanFilter.ps1
    │   ├── Set-PurviewScanFilter.ps1
    │   ├── Get-PurviewScanTrigger.ps1
    │   ├── Set-PurviewScanTrigger.ps1
    │   └── Remove-PurviewScanTrigger.ps1
    ├── Collections/
    │   ├── Get-PurviewCollection.ps1
    │   ├── New-PurviewCollection.ps1
    │   ├── Set-PurviewCollection.ps1
    │   ├── Remove-PurviewCollection.ps1
    │   └── Move-PurviewCollectionResource.ps1
    └── MetadataPolicy/
        ├── Get-PurviewMetadataPolicy.ps1
        ├── Set-PurviewMetadataPolicy.ps1
        └── Get-PurviewMetadataRole.ps1
tests/
└── PurviewPS.Tests.ps1         Pester 5 test suite (mocked, no live instance needed)
```
