function Remove-PurviewRelationship {
    <#
    .SYNOPSIS
        Deletes a relationship by GUID from the Purview Data Map.
    .DESCRIPTION
        DELETE relationship/guid/{guid}
    .PARAMETER Guid
        GUID of the relationship to delete.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Remove-PurviewRelationship -Guid 'abc12345-0000-0000-0000-000000000001'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$Guid,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    if ($PSCmdlet.ShouldProcess($Guid, 'Delete relationship')) {
        return Invoke-PurviewRequest -Resource "relationship/guid/$Guid" -Method DELETE -Connection $Connection
    }
}
