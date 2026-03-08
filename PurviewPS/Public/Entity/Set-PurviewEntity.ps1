function Set-PurviewEntity {
    <#
    .SYNOPSIS
        Updates entities, classifications, business metadata, or labels via
        the Purview Data Map (Atlas v2 Entity API – PUT operations).
    .DESCRIPTION
        Supported operations:

        -Guid -EntityDef               PUT entity/guid/{guid}
        -Guid -ClassificationDef       PUT entity/guid/{guid}/classifications
        -Guid -LabelDef                PUT entity/guid/{guid}/labels
        -TypeName -TypeDef             PUT entity/uniqueAttribute/type/{typeName}
        -TypeName -ClassificationDef   PUT entity/uniqueAttribute/type/{typeName}/classifications
        -TypeName -LabelDef            PUT entity/uniqueAttribute/type/{typeName}/labels
    .PARAMETER Guid
        GUID of the entity to update.
    .PARAMETER EntityDef
        Full entity body for a GUID-targeted update.
    .PARAMETER ClassificationDef
        Updated classification(s) body.
    .PARAMETER LabelDef
        Updated labels array.
    .PARAMETER TypeName
        Entity type name for unique-attribute operations.
    .PARAMETER TypeDef
        Entity body for unique-attribute update.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Set-PurviewEntity -Guid $id -EntityDef $updatedBody
    .EXAMPLE
        Set-PurviewEntity -TypeName 'azure_sql_table' -ClassificationDef $classBody
    #>
    [CmdletBinding(DefaultParameterSetName = 'GuidEntity')]
    param(
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [Parameter(Mandatory, ParameterSetName = 'GuidEntity')]
        [Parameter(Mandatory, ParameterSetName = 'GuidClassifications')]
        [Parameter(Mandatory, ParameterSetName = 'GuidLabels')]
        [string]$Guid,

        [Parameter(Mandatory, ParameterSetName = 'GuidEntity')]
        [object]$EntityDef,

        [Parameter(Mandatory, ParameterSetName = 'GuidClassifications')]
        [Parameter(Mandatory, ParameterSetName = 'UniqueAttributeClassifications')]
        [object]$ClassificationDef,

        [Parameter(Mandatory, ParameterSetName = 'GuidLabels')]
        [Parameter(Mandatory, ParameterSetName = 'UniqueAttributeLabels')]
        [object]$LabelDef,

        [Parameter(Mandatory, ParameterSetName = 'UniqueAttributeEntity')]
        [Parameter(Mandatory, ParameterSetName = 'UniqueAttributeClassifications')]
        [Parameter(Mandatory, ParameterSetName = 'UniqueAttributeLabels')]
        [string]$TypeName,

        [Parameter(Mandatory, ParameterSetName = 'UniqueAttributeEntity')]
        [object]$TypeDef,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    switch ($PSCmdlet.ParameterSetName) {
        'GuidEntity'                     { return Invoke-PurviewRequest -Resource "entity/guid/$Guid" -Method PUT -Body $EntityDef -Connection $Connection }
        'GuidClassifications'            { return Invoke-PurviewRequest -Resource "entity/guid/$Guid/classifications" -Method PUT -Body $ClassificationDef -Connection $Connection }
        'GuidLabels'                     { return Invoke-PurviewRequest -Resource "entity/guid/$Guid/labels" -Method PUT -Body $LabelDef -Connection $Connection }
        'UniqueAttributeEntity'          { return Invoke-PurviewRequest -Resource "entity/uniqueAttribute/type/$TypeName" -Method PUT -Body $TypeDef -Connection $Connection }
        'UniqueAttributeClassifications' { return Invoke-PurviewRequest -Resource "entity/uniqueAttribute/type/$TypeName/classifications" -Method PUT -Body $ClassificationDef -Connection $Connection }
        'UniqueAttributeLabels'          { return Invoke-PurviewRequest -Resource "entity/uniqueAttribute/type/$TypeName/labels" -Method PUT -Body $LabelDef -Connection $Connection }
    }
}
