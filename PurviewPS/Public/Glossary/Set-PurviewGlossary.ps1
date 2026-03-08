function Set-PurviewGlossary {
    <#
    .SYNOPSIS
        Updates glossaries, categories, terms, or assigned entities via the
        Purview Data Map (Atlas v2 Glossary API – PUT operations).
    .DESCRIPTION
        Supported operations:

        -Guid -Glossary              PUT glossary/{guid}
        -Guid -Glossary -Partial     PUT glossary/{guid}/partial
        -Guid -Category              PUT glossary/category/{guid}
        -Guid -Category -Partial     PUT glossary/category/{guid}/partial
        -Guid -Term                  PUT glossary/term/{guid}
        -Guid -Term -Partial         PUT glossary/term/{guid}/partial
        -Guid -AssignedEntities      PUT glossary/terms/{guid}/assignedEntities
    .PARAMETER Guid
        GUID of the glossary, category, or term to update.
    .PARAMETER Glossary
        Updated glossary body.
    .PARAMETER Category
        Updated category body.
    .PARAMETER Term
        Updated term body.
    .PARAMETER AssignedEntities
        Updated assigned entities array.
    .PARAMETER Partial
        Perform a partial (PATCH-style) update rather than a full replace.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Set-PurviewGlossary -Guid $gGuid -Glossary @{ name = 'Finance'; shortDescription = 'Updated' }
    .EXAMPLE
        Set-PurviewGlossary -Guid $termGuid -Term @{ status = 'Approved' } -Partial
    #>
    [CmdletBinding(DefaultParameterSetName = 'Glossary')]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$Guid,

        [Parameter(Mandatory, ParameterSetName = 'Glossary')]
        [object]$Glossary,

        [Parameter(Mandatory, ParameterSetName = 'Category')]
        [object]$Category,

        [Parameter(Mandatory, ParameterSetName = 'Term')]
        [object]$Term,

        [Parameter(Mandatory, ParameterSetName = 'AssignedEntities')]
        [object[]]$AssignedEntities,

        [Parameter(ParameterSetName = 'Glossary')]
        [Parameter(ParameterSetName = 'Category')]
        [Parameter(ParameterSetName = 'Term')]
        [switch]$Partial,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    switch ($PSCmdlet.ParameterSetName) {
        'Glossary' {
            $path = if ($Partial) { "glossary/$Guid/partial" } else { "glossary/$Guid" }
            return Invoke-PurviewRequest -Resource $path -Method PUT -Body $Glossary -Connection $Connection
        }
        'Category' {
            $path = if ($Partial) { "glossary/category/$Guid/partial" } else { "glossary/category/$Guid" }
            return Invoke-PurviewRequest -Resource $path -Method PUT -Body $Category -Connection $Connection
        }
        'Term' {
            $path = if ($Partial) { "glossary/term/$Guid/partial" } else { "glossary/term/$Guid" }
            return Invoke-PurviewRequest -Resource $path -Method PUT -Body $Term -Connection $Connection
        }
        'AssignedEntities' {
            return Invoke-PurviewRequest -Resource "glossary/terms/$Guid/assignedEntities" -Method PUT -Body $AssignedEntities -Connection $Connection
        }
    }
}
