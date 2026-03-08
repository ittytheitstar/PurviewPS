function New-PurviewEntity {
    <#
    .SYNOPSIS
        Creates entities, bulk-imports entities, adds classifications, business
        metadata, or labels via the Purview Data Map (Atlas v2 Entity API).
    .DESCRIPTION
        Supported operations:

        (default)           POST entity           – create/upsert a single entity
        -Bulk               POST entity/bulk      – create/upsert multiple entities
        -Classifications    POST entity/guid/{guid}/classifications
        -BulkClassifications POST entity/bulk/classification
        -BusinessMetadata   POST entity/guid/{guid}/businessmetadata
        -Labels             POST entity/guid/{guid}/labels
        -ImportBusinessMetadata  POST entity/businessmetadata/import
        Unique-attribute variants are also supported.
    .PARAMETER EntityDef
        Full AtlasEntityWithExtInfo or AtlasEntitiesWithExtInfo body for create/upsert.
    .PARAMETER Guid
        Entity GUID required for classification/businessmetadata/label operations.
    .PARAMETER ClassificationDef
        ClassificationAssociateRequest or array of AtlasClassification objects.
    .PARAMETER BusinessMetadataDef
        Business metadata attributes hashtable.
    .PARAMETER BusinessMetadataName
        Business metadata attribute set name (used in namespaced update).
    .PARAMETER LabelsDef
        Array of label strings.
    .PARAMETER TypeName
        Entity type name for unique-attribute operations.
    .PARAMETER Bulk
        Switch to route to the bulk entity endpoint.
    .PARAMETER Classifications
        Switch to add classifications to the entity.
    .PARAMETER BulkClassifications
        Switch to associate a single classification across multiple entities.
    .PARAMETER BusinessMetadata
        Switch to upsert business metadata on a GUID-identified entity.
    .PARAMETER ImportBusinessMetadata
        Switch to bulk-import business metadata via a file-level operation.
    .PARAMETER Labels
        Switch to set labels on an entity.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        $body = @{ entity = @{ typeName = 'DataSet'; attributes = @{ qualifiedName = 'myDS'; name = 'myDS' } } }
        New-PurviewEntity -EntityDef $body
    .EXAMPLE
        New-PurviewEntity -Guid $id -Classifications -ClassificationDef @( @{ typeName = 'PII' } )
    #>
    [CmdletBinding(DefaultParameterSetName = 'Single')]
    param(
        [Parameter(ParameterSetName = 'Single')]
        [Parameter(ParameterSetName = 'Bulk')]
        [object]$EntityDef,

        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [Parameter(ParameterSetName = 'Classifications')]
        [Parameter(ParameterSetName = 'BusinessMetadata')]
        [Parameter(ParameterSetName = 'BusinessMetadataName')]
        [Parameter(ParameterSetName = 'Labels')]
        [string]$Guid,

        [Parameter(ParameterSetName = 'Bulk')]
        [switch]$Bulk,

        [Parameter(ParameterSetName = 'Classifications')]
        [Parameter(ParameterSetName = 'BulkClassifications')]
        [Parameter(ParameterSetName = 'UniqueAttributeClassifications')]
        [object]$ClassificationDef,

        [Parameter(ParameterSetName = 'Classifications')]
        [switch]$Classifications,

        [Parameter(ParameterSetName = 'BulkClassifications')]
        [switch]$BulkClassifications,

        [Parameter(ParameterSetName = 'BusinessMetadata')]
        [Parameter(ParameterSetName = 'BusinessMetadataName')]
        [Parameter(ParameterSetName = 'ImportBusinessMetadata')]
        [object]$BusinessMetadataDef,

        [Parameter(ParameterSetName = 'BusinessMetadata')]
        [switch]$BusinessMetadata,

        [Parameter(ParameterSetName = 'ImportBusinessMetadata')]
        [switch]$ImportBusinessMetadata,

        [Parameter(ParameterSetName = 'BusinessMetadataName')]
        [string]$BusinessMetadataName,

        [Parameter(ParameterSetName = 'Labels')]
        [Parameter(ParameterSetName = 'UniqueAttributeLabels')]
        [object]$LabelsDef,

        [Parameter(ParameterSetName = 'Labels')]
        [switch]$Labels,

        [Parameter(ParameterSetName = 'UniqueAttributeClassifications')]
        [Parameter(ParameterSetName = 'UniqueAttributeLabels')]
        [string]$TypeName,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    switch ($PSCmdlet.ParameterSetName) {
        'Single'                      { return Invoke-PurviewRequest -Resource 'entity' -Method POST -Body $EntityDef -Connection $Connection }
        'Bulk'                        { return Invoke-PurviewRequest -Resource 'entity/bulk' -Method POST -Body $EntityDef -Connection $Connection }
        'Classifications'             { return Invoke-PurviewRequest -Resource "entity/guid/$Guid/classifications" -Method POST -Body $ClassificationDef -Connection $Connection }
        'BulkClassifications'         { return Invoke-PurviewRequest -Resource 'entity/bulk/classification' -Method POST -Body $ClassificationDef -Connection $Connection }
        'BusinessMetadata'            { return Invoke-PurviewRequest -Resource "entity/guid/$Guid/businessmetadata" -Method POST -Body $BusinessMetadataDef -Connection $Connection }
        'BusinessMetadataName'        { return Invoke-PurviewRequest -Resource "entity/guid/$Guid/businessmetadata/$BusinessMetadataName" -Method POST -Body $BusinessMetadataDef -Connection $Connection }
        'ImportBusinessMetadata'      { return Invoke-PurviewRequest -Resource 'entity/businessmetadata/import' -Method POST -Body $BusinessMetadataDef -Connection $Connection }
        'Labels'                      { return Invoke-PurviewRequest -Resource "entity/guid/$Guid/labels" -Method POST -Body $LabelsDef -Connection $Connection }
        'UniqueAttributeClassifications' { return Invoke-PurviewRequest -Resource "entity/uniqueAttribute/type/$TypeName/classifications" -Method POST -Body $ClassificationDef -Connection $Connection }
        'UniqueAttributeLabels'       { return Invoke-PurviewRequest -Resource "entity/uniqueAttribute/type/$TypeName/labels" -Method POST -Body $LabelsDef -Connection $Connection }
    }
}
