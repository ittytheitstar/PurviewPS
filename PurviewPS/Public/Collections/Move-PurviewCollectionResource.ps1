function Move-PurviewCollectionResource {
    <#
    .SYNOPSIS
        Moves assets (entities) from their current collection into a target collection.
    .DESCRIPTION
        POST account/collections/{collectionName}/moveresources

        Accepts a body containing the list of entity GUIDs to move.
    .PARAMETER CollectionName
        Name of the destination collection.
    .PARAMETER ResourceIds
        Array of entity GUIDs to move into the target collection.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Move-PurviewCollectionResource -CollectionName 'finance' -ResourceIds @($guid1, $guid2)
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$CollectionName,

        [Parameter(Mandatory)]
        [string[]]$ResourceIds,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    if ($PSCmdlet.ShouldProcess($CollectionName, "Move $($ResourceIds.Count) resource(s) to collection")) {
        $body = @{ resourceIds = $ResourceIds }
        return Invoke-PurviewRequest `
            -Resource "collections/$CollectionName/moveresources" `
            -Method  POST `
            -Body    $body `
            -ApiType Account `
            -Connection $Connection
    }
}
