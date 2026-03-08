#Requires -Version 5.1
<#
.SYNOPSIS
    PurviewPS - PowerShell module for Microsoft Purview
.DESCRIPTION
    A comprehensive PowerShell module for interacting with Microsoft Purview
    via its REST APIs, covering Data Map (Atlas v2), Scanning, Collections,
    Metadata Policy, and Search/Discovery.
.NOTES
    Version: 2.0.0
#>

#region Module Setup

# Active connection stored at module scope
$script:PurviewConnection = $null

# Dot-source Private helper functions
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
foreach ($file in $Private) {
    try   { . $file.FullName }
    catch { Write-Error "Failed to import private function '$($file.FullName)': $_" }
}

# Dot-source Public functions (all subdirectories)
$Public = @(Get-ChildItem -Path "$PSScriptRoot\Public\**\*.ps1" -Recurse -ErrorAction SilentlyContinue)
foreach ($file in $Public) {
    try   { . $file.FullName }
    catch { Write-Error "Failed to import public function '$($file.FullName)': $_" }
}

#endregion

#region Classes
# Classes are defined here in the root PSM1 so they are available to all
# dot-sourced function files and to callers using 'using module PurviewPS'.

# ── Token / Connection ────────────────────────────────────────────────────────

class PurviewToken {
    [String]$TokenType
    [String]$ExpiresIn
    [String]$ExtExpiresIn
    [DateTime]$ExpiresOn
    [String]$NotBefore
    [String]$Resource
    [String]$AccessToken

    PurviewToken([hashtable]$tokenData) {
        $this.TokenType    = $tokenData.token_type
        $this.ExpiresIn    = $tokenData.expires_in
        $this.ExtExpiresIn = $tokenData.ext_expires_in
        $this.NotBefore    = $tokenData.not_before
        $this.Resource     = $tokenData.resource
        $this.AccessToken  = $tokenData.access_token
        if ($tokenData.expires_on) {
            $this.ExpiresOn = [DateTimeOffset]::FromUnixTimeSeconds([long]$tokenData.expires_on).LocalDateTime
        } else {
            $this.ExpiresOn = (Get-Date).AddHours(1)
        }
    }
}

# ── Atlas Constraint / Attribute ──────────────────────────────────────────────

class AtlasConstraintDef {
    [hashtable]$params
    [String]$type
}

class AtlasAttributeDef {
    # cardinality: SINGLE | LIST | SET
    [String]$cardinality
    [AtlasConstraintDef[]]$constraints
    [String]$defaultValue
    [String]$description
    [bool]$includeInNotification
    [bool]$isIndexable
    [bool]$isOptional
    [bool]$isUnique
    [String]$name
    [hashtable]$options
    [String]$typeName
    [int]$valuesMaxCount
    [int]$valuesMinCount
}

# ── Atlas Type Definitions ────────────────────────────────────────────────────

class AtlasBaseTypeDef {
    # category: PRIMITIVE | OBJECT_ID_TYPE | ENUM | STRUCT | CLASSIFICATION | ENTITY | ARRAY | MAP | RELATIONSHIP | TERM_TEMPLATE
    [String]$category
    [long]$createTime
    [String]$createdBy
    [String]$description
    [String]$guid
    [String]$name
    [hashtable]$options
    [String]$serviceType
    [String]$typeVersion
    [long]$updateTime
    [String]$updatedBy
    [long]$version
    [String]$lastModifiedTS
}

class AtlasStructDef : AtlasBaseTypeDef {
    [AtlasAttributeDef[]]$attributeDefs
}

class AtlasClassificationDef : AtlasStructDef {
    [String[]]$entityTypes
    [String[]]$subTypes
    [String[]]$superTypes
}

class AtlasEntityDef : AtlasStructDef {
    [String[]]$subTypes
    [String[]]$superTypes
    [hashtable[]]$relationshipAttributeDefs
}

class AtlasEnumElementDef {
    [String]$description
    [int]$ordinal
    [String]$value
}

class AtlasEnumDef : AtlasBaseTypeDef {
    [String]$defaultValue
    [AtlasEnumElementDef[]]$elementDefs
}

class AtlasRelationshipEndDef {
    # cardinality: SINGLE | LIST | SET
    [String]$cardinality
    [String]$description
    [bool]$isContainer
    [bool]$isLegacyAttribute
    [String]$name
    [String]$type
}

class AtlasRelationshipDef : AtlasStructDef {
    [AtlasRelationshipEndDef]$endDef1
    [AtlasRelationshipEndDef]$endDef2
    # propagateTags: NONE | ONE_TO_TWO | TWO_TO_ONE | BOTH
    [String]$propagateTags
    # relationshipCategory: ASSOCIATION | AGGREGATION | COMPOSITION
    [String]$relationshipCategory
    [String]$relationshipLabel
}

class TermTemplateDef : AtlasStructDef {}

class AtlasTypesDef {
    [AtlasClassificationDef[]]$classificationDefs
    [AtlasEntityDef[]]$entityDefs
    [AtlasEnumDef[]]$enumDefs
    [AtlasRelationshipDef[]]$relationshipDefs
    [AtlasStructDef[]]$structDefs
    [TermTemplateDef[]]$termTemplateDefs
}

class AtlasTypeDefHeader {
    [String]$category
    [String]$guid
    [String]$name
}

# ── Atlas Entity ──────────────────────────────────────────────────────────────

class TimeBoundary {
    [String]$endTime
    [String]$startTime
    [String]$timeZone
}

class AtlasStruct {
    [hashtable]$attributes
    [String]$typeName
    [String]$lastModifiedTS
}

class AtlasObjectId {
    [String]$guid
    [String]$typeName
    [hashtable]$uniqueAttributes
}

class AtlasTermAssignmentHeader {
    [int]$confidence
    [String]$createdBy
    [String]$description
    [String]$displayText
    [String]$expression
    [String]$relationGuid
    [String]$source
    # status: DISCOVERED | PROPOSED | IMPORTED | VALIDATED | DEPRECATED | OBSOLETE | OTHER
    [String]$status
    [String]$steward
    [String]$termGuid
}

class AtlasClassification : AtlasStruct {
    [String]$entityGuid
    # entityStatus: ACTIVE | DELETED
    [String]$entityStatus
    [bool]$propagate
    [bool]$removePropagationsOnEntityDelete
    [TimeBoundary[]]$validityPeriods
    [String]$source
    [hashtable]$sourceDetails
}

class AtlasEntityHeader : AtlasStruct {
    [String[]]$classificationNames
    [AtlasClassification[]]$classifications
    [String]$displayText
    [String]$guid
    [String[]]$meaningNames
    [AtlasTermAssignmentHeader[]]$meanings
    # status: ACTIVE | DELETED
    [String]$status
}

class AtlasEntity : AtlasStruct {
    [AtlasClassification[]]$classifications
    [long]$createTime
    [String]$createdBy
    [String]$guid
    [String]$homeId
    [AtlasTermAssignmentHeader[]]$meanings
    [int]$provenanceType
    [bool]$proxy
    [hashtable]$relationshipAttributes
    # status: ACTIVE | DELETED
    [String]$status
    [long]$updateTime
    [String]$updatedBy
    [long]$version
    [String]$source
    [hashtable]$sourceDetails
    [hashtable]$contacts
    [hashtable]$labels
}

class AtlasEntityExtInfo {
    [hashtable]$referredEntities
}

class AtlasEntityWithExtInfo : AtlasEntityExtInfo {
    [AtlasEntity]$entity
}

class AtlasEntitiesWithExtInfo : AtlasEntityExtInfo {
    [AtlasEntity[]]$entities
}

class EntityMutationResponse {
    [hashtable]$guidAssignments
    [hashtable]$mutatedEntities
    [AtlasEntityHeader[]]$partialUpdatedEntities
}

class ClassificationAssociateRequest {
    [AtlasClassification]$classification
    [String[]]$entityGuids
}

class AtlasRelatedObjectId : AtlasObjectId {
    [String]$displayText
    [String]$entityStatus
    [AtlasStruct]$relationshipAttributes
    [String]$relationshipGuid
    [String]$relationshipStatus
    [String]$relationshipType
}

# ── Atlas Relationship ────────────────────────────────────────────────────────

class AtlasRelationship : AtlasStruct {
    [AtlasClassification[]]$blockedPropagatedClassifications
    [long]$createTime
    [String]$createdBy
    [AtlasObjectId]$end1
    [AtlasObjectId]$end2
    [String]$guid
    [String]$homeId
    [String]$label
    [String]$propagateTags
    [AtlasClassification[]]$propagatedClassifications
    [int]$provenanceType
    # status: ACTIVE | DELETED
    [String]$status
    [long]$updateTime
    [String]$updatedBy
    [long]$version
}

class AtlasRelationshipWithExtInfo {
    [hashtable]$referredEntities
    [AtlasRelationship]$relationship
}

# ── Atlas Lineage ─────────────────────────────────────────────────────────────

class AtlasLineageInfo {
    [String]$baseEntityGuid
    [hashtable]$guidEntityMap
    [hashtable]$widthCounts
    [int]$lineageDepth
    [int]$lineageWidth
    [bool]$includeParent
    [int]$childrenCount
    # lineageDirection: INPUT | OUTPUT | BOTH
    [String]$lineageDirection
    [hashtable[]]$parentRelations
    [hashtable[]]$relations
}

# ── Glossary ──────────────────────────────────────────────────────────────────

class ResourceLink {
    [String]$displayName
    [String]$url
}

class AtlasGlossaryHeader {
    [String]$displayText
    [String]$glossaryGuid
    [String]$relationGuid
}

class AtlasRelatedCategoryHeader {
    [String]$categoryGuid
    [String]$description
    [String]$displayText
    [String]$parentCategoryGuid
    [String]$relationGuid
}

class AtlasRelatedTermHeader {
    [String]$description
    [String]$displayText
    [String]$expression
    [String]$relationGuid
    [String]$source
    [String]$status
    [String]$steward
    [String]$termGuid
}

class AtlasGlossaryBaseObject {
    [String]$guid
    [AtlasClassification[]]$classifications
    [String]$longDescription
    [String]$name
    [String]$qualifiedName
    [String]$shortDescription
    [String]$lastModifiedTS
}

class AtlasGlossary : AtlasGlossaryBaseObject {
    [AtlasRelatedCategoryHeader[]]$categories
    [String]$language
    [AtlasRelatedTermHeader[]]$terms
    [String]$usage
}

class AtlasGlossaryCategory : AtlasGlossaryBaseObject {
    [AtlasGlossaryHeader]$anchor
    [AtlasRelatedCategoryHeader[]]$childrenCategories
    [AtlasRelatedCategoryHeader]$parentCategory
    [AtlasRelatedTermHeader[]]$terms
}

class AtlasTermCategorizationHeader {
    [String]$categoryGuid
    [String]$description
    [String]$displayText
    [String]$relationGuid
    # status: DRAFT | ACTIVE | DEPRECATED | OBSOLETE | OTHER
    [String]$status
}

class AtlasGlossaryTerm : AtlasGlossaryBaseObject {
    [String]$abbreviation
    [AtlasGlossaryHeader]$anchor
    [AtlasRelatedTermHeader[]]$antonyms
    [long]$createTime
    [String]$createdBy
    [long]$updateTime
    [String]$updatedBy
    # status: Draft | Approved | Alert | Expired
    [String]$status
    [ResourceLink[]]$resources
    [hashtable]$contacts
    [hashtable]$attributes
    [AtlasRelatedObjectId[]]$assignedEntities
    [AtlasTermCategorizationHeader[]]$categories
    [AtlasRelatedTermHeader[]]$classifies
    [String[]]$examples
    [AtlasRelatedTermHeader[]]$isA
    [AtlasRelatedTermHeader[]]$preferredTerms
    [AtlasRelatedTermHeader[]]$preferredToTerms
    [AtlasRelatedTermHeader[]]$replacedBy
    [AtlasRelatedTermHeader[]]$replacementTerms
    [AtlasRelatedTermHeader[]]$seeAlso
    [AtlasRelatedTermHeader[]]$synonyms
    [AtlasRelatedTermHeader[]]$translatedTerms
    [AtlasRelatedTermHeader[]]$translationTerms
    [String]$usage
    [AtlasRelatedTermHeader[]]$validValues
    [AtlasRelatedTermHeader[]]$validValuesFor
}

class AtlasGlossaryExtInfo : AtlasGlossary {
    [hashtable]$categoryInfo
    [hashtable]$termInfo
}

class ImportCSVOperation {
    [String]$id
    # status: Pending | Succeeded | Failed | Canceled
    [String]$status
    [long]$createTime
    [long]$lastUpdateTime
    [hashtable]$properties
    [hashtable]$error
}

# ── Search / Discovery ────────────────────────────────────────────────────────

class SearchFacetItemValue {
    [int]$count
    [String]$value
}

class SearchHighlights {
    [String[]]$id
    [String[]]$qualifiedName
    [String[]]$name
    [String[]]$description
    [String[]]$entityType
}

class contactSearchResultValue {
    [String]$id
    [String]$info
    [String]$contactType
}

class termSearchResultValue {
    [String]$name
    [String]$glossaryName
}

class SearchResultValue {
    [double]${@search.score}
    [SearchHighlights]${@search.highlights}
    [String]$id
    [String]$name
    [String]$qualifiedName
    [String]$description
    [String]$entityType
    [String]$owner
    [String[]]$classification
    [String[]]$label
    [termSearchResultValue[]]$term
    [contactSearchResultValue[]]$contact
    [String[]]$assetType
    [String]$collectionId
    [String]$createTime
    [String]$updateTime
    [String]$objectType
}

class SearchFacetResultValue {
    [SearchFacetItemValue[]]$assetType
    [SearchFacetItemValue[]]$classification
    [SearchFacetItemValue[]]$classificationCategory
    [SearchFacetItemValue[]]$contactId
    [SearchFacetItemValue[]]$fileExtension
    [SearchFacetItemValue[]]$label
    [SearchFacetItemValue[]]$term
    [SearchFacetItemValue[]]$objectType
}

class AdvancedSearchResult {
    [int]${@search.count}
    [SearchFacetResultValue]${@search.facets}
    [SearchResultValue[]]$value
}

class SuggestResultValue {
    [double]${@search.score}
    [String]${@search.text}
    [String]$id
    [String]$name
    [String]$qualifiedName
    [String]$description
    [String]$entityType
    [String]$owner
    [String[]]$classification
    [String[]]$label
    [termSearchResultValue[]]$term
    [contactSearchResultValue[]]$contact
    [String[]]$assetType
}

class SuggestResult {
    [SuggestResultValue[]]$value
}

class AutocompleteResultValue {
    [String]$text
    [String]$queryPlusText
}

class AutocompleteResult {
    [AutocompleteResultValue[]]$value
}

class SearchRequest {
    [String]$keywords
    [int]$offset
    [int]$limit
    [hashtable]$filter
    [hashtable[]]$facets
    [hashtable]$taxonomySetting
}

class SuggestRequest {
    [String]$keywords
    [int]$limit
    [hashtable]$filter
}

class AutoCompleteRequest {
    [String]$keyword
    [int]$limit
    [hashtable]$filter
}

# ── Metadata Policy ───────────────────────────────────────────────────────────

class MetadataRole {
    [String]$id
    [String]$name
    [String]$type
    [String]$friendlyName
    [String]$description
    [String[]]$cnfCondition
    [String[]]$dnfCondition
}

class MetadataPolicy {
    [String]$id
    [String]$name
    [String]$version
    [hashtable]$properties
}

#endregion

#region Module Exports

# Collect all public function names from loaded files
$exportedFunctions = $Public | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) }

Export-ModuleMember -Function $exportedFunctions

# Backward-compatibility aliases (old names -> new names)
$aliases = @{
    'New-PurviewClient'   = 'Connect-Purview'
    'Get-Entity'          = 'Get-PurviewEntity'
    'Add-Entity'          = 'New-PurviewEntity'
    'Set-Entity'          = 'Set-PurviewEntity'
    'Remove-Entity'       = 'Remove-PurviewEntity'
    'Get-TypeDefs'        = 'Get-PurviewTypeDefinition'
    'Add-TypeDefs'        = 'New-PurviewTypeDefinition'
    'Set-TypeDefs'        = 'Set-PurviewTypeDefinition'
    'Remove-TypeDefs'     = 'Remove-PurviewTypeDefinition'
    'Get-Relationship'    = 'Get-PurviewRelationship'
    'Add-Relationship'    = 'New-PurviewRelationship'
    'Set-Relationship'    = 'Set-PurviewRelationship'
    'Remove-Relationship' = 'Remove-PurviewRelationship'
    'Get-Lineage'         = 'Get-PurviewLineage'
    'Get-Glossary'        = 'Get-PurviewGlossary'
    'Add-Glossary'        = 'New-PurviewGlossary'
    'Set-Glossary'        = 'Set-PurviewGlossary'
    'Remove-Glossary'     = 'Remove-PurviewGlossary'
    'New-Search'          = 'Search-Purview'
}

foreach ($alias in $aliases.GetEnumerator()) {
    if (Get-Command $alias.Value -ErrorAction SilentlyContinue) {
        Set-Alias -Name $alias.Key -Value $alias.Value -Scope Global -Force
    }
}

Export-ModuleMember -Alias *

#endregion
