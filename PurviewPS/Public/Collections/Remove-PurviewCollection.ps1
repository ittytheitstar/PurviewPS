function Remove-PurviewCollection {
    <#
    .SYNOPSIS
        Deletes a collection from the Purview account (DELETE account/collections/{name}).
    .PARAMETER Name
        Internal name of the collection to delete.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Remove-PurviewCollection -Name 'obsolete-collection'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    if ($PSCmdlet.ShouldProcess($Name, 'Delete collection')) {
        return Invoke-PurviewRequest -Resource "collections/$Name" -Method DELETE -ApiType Account -Connection $Connection
    }
}
