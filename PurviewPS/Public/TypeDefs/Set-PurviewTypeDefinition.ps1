function Set-PurviewTypeDefinition {
    <#
    .SYNOPSIS
        Updates existing type definitions in the Purview Data Map (Atlas v2 – PUT types/typedefs).
    .DESCRIPTION
        Sends an AtlasTypesDef payload to the PUT types/typedefs endpoint.
        Use New-PurviewTypeDefinition (POST) to create new type defs.
    .PARAMETER TypeDefs
        An AtlasTypesDef object or equivalent hashtable containing the updated
        type definitions.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        $td = @{ entityDefs = @( @{ name = 'MyCustomType'; description = 'Updated description' } ) }
        Set-PurviewTypeDefinition -TypeDefs $td
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$TypeDefs,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    return Invoke-PurviewRequest -Resource 'types/typedefs' -Method PUT -Body $TypeDefs -Connection $Connection
}
