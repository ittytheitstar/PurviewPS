function Remove-PurviewTypeDefinition {
    <#
    .SYNOPSIS
        Deletes one or more type definitions from the Purview Data Map.
    .DESCRIPTION
        Supports two operations:

        -TypeDefs    DELETE types/typedefs  (bulk delete via body)
        -Name        DELETE types/typedef/name/{name}  (single by name)
    .PARAMETER TypeDefs
        An AtlasTypesDef body identifying which type definitions to delete.
    .PARAMETER Name
        Name of a single type definition to delete.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Remove-PurviewTypeDefinition -Name 'MyObsoleteType'
    .EXAMPLE
        Remove-PurviewTypeDefinition -TypeDefs $bulkDeleteBody
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByName', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Bulk')]
        [object]$TypeDefs,

        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$Name,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ByName' {
            if ($PSCmdlet.ShouldProcess($Name, 'Delete type definition')) {
                return Invoke-PurviewRequest -Resource "types/typedef/name/$Name" -Method DELETE -Connection $Connection
            }
        }
        'Bulk' {
            if ($PSCmdlet.ShouldProcess('bulk type definitions', 'Delete')) {
                return Invoke-PurviewRequest -Resource 'types/typedefs' -Method DELETE -Body $TypeDefs -Connection $Connection
            }
        }
    }
}
