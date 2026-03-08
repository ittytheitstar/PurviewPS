function Get-PurviewRelationship {
    <#
    .SYNOPSIS
        Retrieves a relationship by GUID from the Purview Data Map.
    .DESCRIPTION
        GET relationship/guid/{guid}

        Optionally request extended info (referred entities) via -ExtendedInfo.
    .PARAMETER Guid
        GUID of the relationship to retrieve.
    .PARAMETER ExtendedInfo
        When set, the response includes referred entity information.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Get-PurviewRelationship -Guid 'abc12345-0000-0000-0000-000000000001'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$Guid,

        [switch]$ExtendedInfo,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    $resource = "relationship/guid/$Guid"
    if ($ExtendedInfo) { $resource += '?extendedInfo=true' }

    return Invoke-PurviewRequest -Resource $resource -Connection $Connection
}
