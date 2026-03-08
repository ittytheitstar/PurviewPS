function Get-PurviewLineage {
    <#
    .SYNOPSIS
        Retrieves lineage information for an entity in the Purview Data Map.
    .DESCRIPTION
        Supports lineage retrieval by entity GUID or by unique attribute (type + qualifiedName).

        ByGuid             GET lineage/{guid}?direction=...&depth=...
        ByUniqueAttribute  GET lineage/uniqueAttribute/type/{typeName}?direction=...
    .PARAMETER Guid
        GUID of the entity whose lineage to retrieve.
    .PARAMETER TypeName
        Type name for unique-attribute lineage lookup.
    .PARAMETER QualifiedName
        qualifiedName attribute value used with -TypeName.
    .PARAMETER Direction
        Lineage direction: INPUT | OUTPUT | BOTH (default: BOTH).
    .PARAMETER Depth
        Number of hops to traverse (default: 3).
    .PARAMETER Width
        Maximum breadth at each hop (default: 10).
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Get-PurviewLineage -Guid 'abc12345-0000-0000-0000-000000000001'
    .EXAMPLE
        Get-PurviewLineage -Guid $id -Direction INPUT -Depth 5
    .EXAMPLE
        Get-PurviewLineage -TypeName 'azure_sql_table' -QualifiedName 'mssql://server/db/schema/table'
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByGuid')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByGuid')]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$Guid,

        [Parameter(Mandatory, ParameterSetName = 'ByUniqueAttribute')]
        [string]$TypeName,

        [Parameter(ParameterSetName = 'ByUniqueAttribute')]
        [string]$QualifiedName,

        [ValidateSet('INPUT', 'OUTPUT', 'BOTH')]
        [string]$Direction = 'BOTH',

        [ValidateRange(1, 25)]
        [int]$Depth = 3,

        [ValidateRange(1, 25)]
        [int]$Width = 10,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    $qs = "direction=$Direction&depth=$Depth&width=$Width"

    switch ($PSCmdlet.ParameterSetName) {
        'ByGuid' {
            return Invoke-PurviewRequest -Resource "lineage/$($Guid)?$qs" -Connection $Connection
        }
        'ByUniqueAttribute' {
            $resource = "lineage/uniqueAttribute/type/$($TypeName)?$qs"
            if ($QualifiedName) {
                $resource += "&attr:qualifiedName=$([Uri]::EscapeDataString($QualifiedName))"
            }
            return Invoke-PurviewRequest -Resource $resource -Connection $Connection
        }
    }
}
