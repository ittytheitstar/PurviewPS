function Remove-PurviewGlossary {
    <#
    .SYNOPSIS
        Deletes glossaries, categories, terms, or assigned-entity links from
        the Purview Data Map (Atlas v2 Glossary API – DELETE operations).
    .DESCRIPTION
        Supported operations:

        -Guid                       DELETE glossary/{guid}
        -Guid -Category             DELETE glossary/category/{guid}
        -Guid -Term                 DELETE glossary/term/{guid}
        -Guid -Term -AssignedEntities DELETE glossary/terms/{guid}/assignedEntities
    .PARAMETER Guid
        GUID of the resource to delete.
    .PARAMETER Category
        Switch – target the glossary category.
    .PARAMETER Term
        Switch – target a glossary term.
    .PARAMETER AssignedEntities
        Switch – remove all assigned entity links from a term.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Remove-PurviewGlossary -Guid $glossaryGuid
    .EXAMPLE
        Remove-PurviewGlossary -Guid $termGuid -Term
    #>
    [CmdletBinding(DefaultParameterSetName = 'Glossary', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$Guid,

        [Parameter(Mandatory, ParameterSetName = 'Category')]
        [switch]$Category,

        [Parameter(Mandatory, ParameterSetName = 'Term')]
        [Parameter(Mandatory, ParameterSetName = 'TermAssignedEntities')]
        [switch]$Term,

        [Parameter(Mandatory, ParameterSetName = 'TermAssignedEntities')]
        [switch]$AssignedEntities,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    switch ($PSCmdlet.ParameterSetName) {
        'Glossary' {
            if ($PSCmdlet.ShouldProcess($Guid, 'Delete glossary')) {
                return Invoke-PurviewRequest -Resource "glossary/$Guid" -Method DELETE -Connection $Connection
            }
        }
        'Category' {
            if ($PSCmdlet.ShouldProcess($Guid, 'Delete glossary category')) {
                return Invoke-PurviewRequest -Resource "glossary/category/$Guid" -Method DELETE -Connection $Connection
            }
        }
        'Term' {
            if ($PSCmdlet.ShouldProcess($Guid, 'Delete glossary term')) {
                return Invoke-PurviewRequest -Resource "glossary/term/$Guid" -Method DELETE -Connection $Connection
            }
        }
        'TermAssignedEntities' {
            if ($PSCmdlet.ShouldProcess($Guid, 'Delete term assigned entities')) {
                return Invoke-PurviewRequest -Resource "glossary/terms/$Guid/assignedEntities" -Method DELETE -Connection $Connection
            }
        }
    }
}
