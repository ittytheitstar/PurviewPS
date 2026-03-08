function Set-PurviewCollection {
    <#
    .SYNOPSIS
        Updates an existing collection in the Purview account (PUT account/collections/{name}).
    .DESCRIPTION
        Uses the same PUT endpoint as New-PurviewCollection; provided as a
        semantically distinct cmdlet for the update case.
    .PARAMETER Name
        Internal name of the collection to update.
    .PARAMETER CollectionDef
        Updated collection properties (friendlyName, description, etc.).
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Set-PurviewCollection -Name 'finance' -CollectionDef @{ friendlyName = 'Finance Dept' }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [object]$CollectionDef,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    return Invoke-PurviewRequest -Resource "collections/$Name" -Method PUT -Body $CollectionDef -ApiType Account -Connection $Connection
}
