function Remove-PurviewEntity {
    <#
    .SYNOPSIS
        Deletes entities, classifications, business metadata, or labels from the
        Purview Data Map (Atlas v2 Entity API – DELETE operations).
    .DESCRIPTION
        Supported operations:

        -Guid                              DELETE entity/guid/{guid}
        -Guids                             DELETE entity/bulk?guid=...
        -Guid -ClassificationName          DELETE entity/guid/{guid}/classification/{name}
        -Guid -BusinessMetadata            DELETE entity/guid/{guid}/businessmetadata
        -Guid -BusinessMetadataName        DELETE entity/guid/{guid}/businessmetadata/{name}
        -Guid -Labels                      DELETE entity/guid/{guid}/labels
        -TypeName                          DELETE entity/uniqueAttribute/type/{typeName}
        -TypeName -ClassificationName      DELETE entity/uniqueAttribute/type/{typeName}/classification/{name}
        -TypeName -Labels                  DELETE entity/uniqueAttribute/type/{typeName}/labels
    .PARAMETER Guid
        GUID of the entity to delete (or modify).
    .PARAMETER Guids
        Array of GUIDs for a bulk delete.
    .PARAMETER ClassificationName
        Classification name to remove from the entity.
    .PARAMETER BusinessMetadata
        Switch – removes all business metadata from the entity.
    .PARAMETER BusinessMetadataName
        Removes a specific business metadata attribute set from the entity.
    .PARAMETER Labels
        Switch – removes all labels from the entity (or type-identified entity).
    .PARAMETER TypeName
        Entity type name for unique-attribute operations.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Remove-PurviewEntity -Guid 'abc12345-0000-0000-0000-000000000001'
    .EXAMPLE
        Remove-PurviewEntity -Guids @('guid1','guid2')
    .EXAMPLE
        Remove-PurviewEntity -Guid $id -ClassificationName 'PII'
    .EXAMPLE
        Remove-PurviewEntity -TypeName 'azure_sql_table' -Labels
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByGuid', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByGuid')]
        [Parameter(Mandatory, ParameterSetName = 'GuidClassification')]
        [Parameter(Mandatory, ParameterSetName = 'GuidBusinessMetadata')]
        [Parameter(Mandatory, ParameterSetName = 'GuidBusinessMetadataName')]
        [Parameter(Mandatory, ParameterSetName = 'GuidLabels')]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$Guid,

        [Parameter(Mandatory, ParameterSetName = 'Bulk')]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string[]]$Guids,

        [Parameter(Mandatory, ParameterSetName = 'GuidClassification')]
        [Parameter(Mandatory, ParameterSetName = 'UniqueAttributeClassification')]
        [string]$ClassificationName,

        [Parameter(ParameterSetName = 'GuidBusinessMetadata')]
        [switch]$BusinessMetadata,

        [Parameter(Mandatory, ParameterSetName = 'GuidBusinessMetadataName')]
        [string]$BusinessMetadataName,

        [Parameter(Mandatory, ParameterSetName = 'GuidLabels')]
        [Parameter(Mandatory, ParameterSetName = 'UniqueAttributeLabels')]
        [switch]$Labels,

        [Parameter(Mandatory, ParameterSetName = 'UniqueAttribute')]
        [Parameter(Mandatory, ParameterSetName = 'UniqueAttributeClassification')]
        [Parameter(Mandatory, ParameterSetName = 'UniqueAttributeLabels')]
        [string]$TypeName,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    switch ($PSCmdlet.ParameterSetName) {

        'ByGuid' {
            if ($PSCmdlet.ShouldProcess($Guid, 'Delete entity')) {
                return Invoke-PurviewRequest -Resource "entity/guid/$Guid" -Method DELETE -Connection $Connection
            }
        }
        'Bulk' {
            $guidQs = ($Guids | ForEach-Object { "guid=$_" }) -join '&'
            if ($PSCmdlet.ShouldProcess($Guids -join ', ', 'Bulk delete entities')) {
                return Invoke-PurviewRequest -Resource "entity/bulk?$guidQs" -Method DELETE -Connection $Connection
            }
        }
        'GuidClassification' {
            if ($PSCmdlet.ShouldProcess("$Guid / $ClassificationName", 'Delete classification')) {
                return Invoke-PurviewRequest -Resource "entity/guid/$Guid/classification/$ClassificationName" -Method DELETE -Connection $Connection
            }
        }
        'GuidBusinessMetadata' {
            if ($PSCmdlet.ShouldProcess($Guid, 'Delete business metadata')) {
                return Invoke-PurviewRequest -Resource "entity/guid/$Guid/businessmetadata" -Method DELETE -Connection $Connection
            }
        }
        'GuidBusinessMetadataName' {
            if ($PSCmdlet.ShouldProcess("$Guid / $BusinessMetadataName", 'Delete business metadata set')) {
                return Invoke-PurviewRequest -Resource "entity/guid/$Guid/businessmetadata/$BusinessMetadataName" -Method DELETE -Connection $Connection
            }
        }
        'GuidLabels' {
            if ($PSCmdlet.ShouldProcess($Guid, 'Delete labels')) {
                return Invoke-PurviewRequest -Resource "entity/guid/$Guid/labels" -Method DELETE -Connection $Connection
            }
        }
        'UniqueAttribute' {
            if ($PSCmdlet.ShouldProcess($TypeName, 'Delete entity by unique attribute')) {
                return Invoke-PurviewRequest -Resource "entity/uniqueAttribute/type/$TypeName" -Method DELETE -Connection $Connection
            }
        }
        'UniqueAttributeClassification' {
            if ($PSCmdlet.ShouldProcess("$TypeName / $ClassificationName", 'Delete classification by unique attribute')) {
                return Invoke-PurviewRequest -Resource "entity/uniqueAttribute/type/$TypeName/classification/$ClassificationName" -Method DELETE -Connection $Connection
            }
        }
        'UniqueAttributeLabels' {
            if ($PSCmdlet.ShouldProcess($TypeName, 'Delete labels by unique attribute')) {
                return Invoke-PurviewRequest -Resource "entity/uniqueAttribute/type/$TypeName/labels" -Method DELETE -Connection $Connection
            }
        }
    }
}
