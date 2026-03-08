function Get-PurviewTypeDefinition {
    <#
    .SYNOPSIS
        Retrieves type definitions from the Purview Data Map (Atlas v2 Types API).
    .DESCRIPTION
        Supports querying the full type definition store or individual type defs
        by name or GUID across all categories: businessmetadata, classification,
        entity, enum, relationship, struct, and the generic typedef endpoint.

        -All               GET types/typedefs
        -Headers           GET types/typedefs/headers
        -Guid              GET types/typedef/guid/{guid}
        -Name              GET types/typedef/name/{name}
        -Guid -Category    GET types/{category}def/guid/{guid}
        -Name -Category    GET types/{category}def/name/{name}
    .PARAMETER All
        Return all type definitions.
    .PARAMETER Headers
        Return type definition headers only (lighter payload).
    .PARAMETER Guid
        GUID of the type definition to retrieve.
    .PARAMETER Name
        Name of the type definition to retrieve.
    .PARAMETER Category
        Category of the type def: BusinessMetadata | Classification | Entity |
        Enum | Relationship | Struct.  Used together with -Guid or -Name.
    .PARAMETER TypeName
        Optional type name filter applied when listing all type defs.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Get-PurviewTypeDefinition -All
    .EXAMPLE
        Get-PurviewTypeDefinition -Name 'azure_sql_table' -Category Entity
    .EXAMPLE
        Get-PurviewTypeDefinition -Guid 'abc12345-0000-0000-0000-000000000001' -Category Classification
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [Parameter(ParameterSetName = 'All')]
        [switch]$All,

        [Parameter(Mandatory, ParameterSetName = 'Headers')]
        [switch]$Headers,

        [Parameter(Mandatory, ParameterSetName = 'ByGuid')]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$Guid,

        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$Name,

        [Parameter(ParameterSetName = 'ByGuid')]
        [Parameter(ParameterSetName = 'ByName')]
        [ValidateSet('BusinessMetadata', 'Classification', 'Entity', 'Enum', 'Relationship', 'Struct')]
        [string]$Category,

        [Parameter(ParameterSetName = 'All')]
        [string]$TypeName,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    switch ($PSCmdlet.ParameterSetName) {
        'All' {
            $resource = 'types/typedefs'
            if ($TypeName) { $resource += "?type=$TypeName" }
            return Invoke-PurviewRequest -Resource $resource -Connection $Connection
        }
        'Headers' {
            return Invoke-PurviewRequest -Resource 'types/typedefs/headers' -Connection $Connection
        }
        'ByGuid' {
            if ($Category) {
                $cat = $Category.ToLower()
                return Invoke-PurviewRequest -Resource "types/${cat}def/guid/$Guid" -Connection $Connection
            }
            return Invoke-PurviewRequest -Resource "types/typedef/guid/$Guid" -Connection $Connection
        }
        'ByName' {
            if ($Category) {
                $cat = $Category.ToLower()
                return Invoke-PurviewRequest -Resource "types/${cat}def/name/$Name" -Connection $Connection
            }
            return Invoke-PurviewRequest -Resource "types/typedef/name/$Name" -Connection $Connection
        }
    }
}
