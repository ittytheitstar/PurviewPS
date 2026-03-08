function New-PurviewTypeDefinition {
    <#
    .SYNOPSIS
        Creates new type definitions in the Purview Data Map (Atlas v2 – POST types/typedefs).
    .DESCRIPTION
        Sends an AtlasTypesDef payload to the POST types/typedefs endpoint.
        Use Set-PurviewTypeDefinition (PUT) for updates.
    .PARAMETER TypeDefs
        An AtlasTypesDef object or equivalent hashtable containing the type
        definitions to create.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        $td = @{ entityDefs = @( @{ name = 'MyCustomType'; superTypes = @('DataSet') } ) }
        New-PurviewTypeDefinition -TypeDefs $td
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$TypeDefs,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    return Invoke-PurviewRequest -Resource 'types/typedefs' -Method POST -Body $TypeDefs -Connection $Connection
}
