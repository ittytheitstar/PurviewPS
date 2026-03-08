function Set-PurviewRelationship {
    <#
    .SYNOPSIS
        Updates an existing relationship in the Purview Data Map (PUT relationship).
    .PARAMETER Relationship
        An AtlasRelationship object or equivalent hashtable with the updated values.
        The payload must include the relationship guid.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        $rel = Get-PurviewRelationship -Guid $id
        $rel.attributes.comment = 'Updated comment'
        Set-PurviewRelationship -Relationship $rel
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Relationship,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    return Invoke-PurviewRequest -Resource 'relationship' -Method PUT -Body $Relationship -Connection $Connection
}
