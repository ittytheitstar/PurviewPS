function Get-PurviewEntity {
    <#
    .SYNOPSIS
        Retrieves entities, classifications, audit history, or headers from the
        Purview Data Map (Atlas v2 Entity API).
    .DESCRIPTION
        Supports the following parameter sets:

        ByGuid             GET entity/guid/{guid}
        ByGuid -Headers    GET entity/guid/{guid}/header
        ByGuid -Audit      GET entity/guid/{guid}/audit
        ByGuid -Classifications               GET entity/guid/{guid}/classifications
        ByGuid -ClassificationName <name>     GET entity/guid/{guid}/classification/{name}
        Bulk               GET entity/bulk?guid=...
        Bulk -Headers      GET entity/bulk/headers
        ByUniqueAttribute  GET entity/uniqueAttribute/type/{typeName}
        BusinessMetadataTemplate  GET entity/businessmetadata/import/template
    .PARAMETER Guid
        GUID of a single entity to retrieve.
    .PARAMETER Guids
        Array of GUIDs for a bulk entity retrieval.
    .PARAMETER TypeName
        Entity type name used for unique-attribute lookup.
    .PARAMETER QualifiedName
        qualifiedName attribute value; used with -TypeName.
    .PARAMETER Headers
        Return header objects (lighter payload) instead of full entities.
    .PARAMETER Classifications
        Return all classifications applied to the entity.
    .PARAMETER ClassificationName
        Return a single named classification applied to the entity.
    .PARAMETER Audit
        Return the audit history for the entity.
    .PARAMETER BusinessMetadataTemplate
        Download the CSV import template for business metadata.
    .PARAMETER MinExtInfo
        When set, the API will not return referred entities.
    .PARAMETER IgnoreRelationships
        When set, relationship attributes are excluded from the response.
    .PARAMETER Connection
        Optional explicit connection; defaults to the active module connection.
    .EXAMPLE
        Get-PurviewEntity -Guid 'abc12345-0000-0000-0000-000000000001'
    .EXAMPLE
        Get-PurviewEntity -Guids @('guid1','guid2')
    .EXAMPLE
        Get-PurviewEntity -TypeName 'azure_sql_table' -QualifiedName 'mssql://server/db/schema/table'
    .EXAMPLE
        Get-PurviewEntity -Guid $id -Audit
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByGuid')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByGuid')]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$Guid,

        [Parameter(ParameterSetName = 'Bulk')]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string[]]$Guids,

        [Parameter(Mandatory, ParameterSetName = 'ByUniqueAttribute')]
        [string]$TypeName,

        [Parameter(ParameterSetName = 'ByUniqueAttribute')]
        [string]$QualifiedName,

        [Parameter(ParameterSetName = 'ByGuid')]
        [Parameter(ParameterSetName = 'Bulk')]
        [switch]$Headers,

        [Parameter(ParameterSetName = 'ByGuid')]
        [switch]$Classifications,

        [Parameter(ParameterSetName = 'ByGuid')]
        [string]$ClassificationName,

        [Parameter(ParameterSetName = 'ByGuid')]
        [switch]$Audit,

        [Parameter(ParameterSetName = 'BusinessMetadataTemplate')]
        [switch]$BusinessMetadataTemplate,

        [Parameter(ParameterSetName = 'ByGuid')]
        [Parameter(ParameterSetName = 'Bulk')]
        [Parameter(ParameterSetName = 'ByUniqueAttribute')]
        [switch]$MinExtInfo,

        [Parameter(ParameterSetName = 'ByGuid')]
        [Parameter(ParameterSetName = 'Bulk')]
        [Parameter(ParameterSetName = 'ByUniqueAttribute')]
        [switch]$IgnoreRelationships,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    switch ($PSCmdlet.ParameterSetName) {

        'ByGuid' {
            if ($Audit)              { return Invoke-PurviewRequest -Resource "entity/guid/$Guid/audit" -Connection $Connection }
            if ($ClassificationName) { return Invoke-PurviewRequest -Resource "entity/guid/$Guid/classification/$ClassificationName" -Connection $Connection }
            if ($Classifications)    { return Invoke-PurviewRequest -Resource "entity/guid/$Guid/classifications" -Connection $Connection }
            if ($Headers)            { return Invoke-PurviewRequest -Resource "entity/guid/$Guid/header" -Connection $Connection }

            $qs = @()
            if ($MinExtInfo)          { $qs += 'minExtInfo=true' }
            if ($IgnoreRelationships) { $qs += 'ignoreRelationships=true' }
            $resource = "entity/guid/$Guid"
            if ($qs) { $resource += '?' + ($qs -join '&') }
            return Invoke-PurviewRequest -Resource $resource -Connection $Connection
        }

        'Bulk' {
            if ($Headers) { return Invoke-PurviewRequest -Resource "entity/bulk/headers" -Connection $Connection }

            if ($Guids) {
                $guidQs = ($Guids | ForEach-Object { "guid=$_" }) -join '&'
                $qs = @($guidQs)
                if ($MinExtInfo)          { $qs += 'minExtInfo=true' }
                if ($IgnoreRelationships) { $qs += 'ignoreRelationships=true' }
                return Invoke-PurviewRequest -Resource "entity/bulk?$($qs -join '&')" -Connection $Connection
            }
            return Invoke-PurviewRequest -Resource "entity/bulk" -Connection $Connection
        }

        'ByUniqueAttribute' {
            $resource = "entity/uniqueAttribute/type/$TypeName"
            $qs = @()
            if ($QualifiedName)       { $qs += "attr:qualifiedName=$([Uri]::EscapeDataString($QualifiedName))" }
            if ($MinExtInfo)          { $qs += 'minExtInfo=true' }
            if ($IgnoreRelationships) { $qs += 'ignoreRelationships=true' }
            if ($qs) { $resource += '?' + ($qs -join '&') }
            return Invoke-PurviewRequest -Resource $resource -Connection $Connection
        }

        'BusinessMetadataTemplate' {
            return Invoke-PurviewRequest -Resource "entity/businessmetadata/import/template" -Connection $Connection
        }
    }
}
