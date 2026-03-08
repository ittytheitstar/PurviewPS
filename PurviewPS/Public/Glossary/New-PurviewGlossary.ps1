function New-PurviewGlossary {
    <#
    .SYNOPSIS
        Creates glossaries, categories, terms, or assigned-entity links via the
        Purview Data Map (Atlas v2 Glossary API – POST operations).
    .DESCRIPTION
        Supported operations:

        -Glossary           POST glossary           – create glossary
        -Glossaries (bulk)  POST glossary/import    – bulk-import glossaries
        -Category           POST glossary/category  – create category
        -Categories (bulk)  POST glossary/categories – create multiple categories
        -Term               POST glossary/term       – create term
        -Terms (bulk)       POST glossary/terms      – create multiple terms
        -AssignedEntities   POST glossary/terms/{guid}/assignedEntities
    .PARAMETER Glossary
        Single glossary body (AtlasGlossary or hashtable).
    .PARAMETER Glossaries
        Array of glossary bodies for bulk import.
    .PARAMETER Category
        Single category body.
    .PARAMETER Categories
        Array of category bodies for bulk creation.
    .PARAMETER Term
        Single term body.
    .PARAMETER Terms
        Array of term bodies for bulk creation.
    .PARAMETER AssignedEntities
        Array of AtlasRelatedObjectId objects to assign to a term.
    .PARAMETER Guid
        Term GUID required for -AssignedEntities.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        $g = @{ name = 'Finance Glossary'; shortDescription = 'Finance terms' }
        New-PurviewGlossary -Glossary $g
    .EXAMPLE
        $term = @{ name = 'Revenue'; anchor = @{ glossaryGuid = $gGuid }; status = 'Draft' }
        New-PurviewGlossary -Term $term
    .EXAMPLE
        New-PurviewGlossary -AssignedEntities $entities -Guid $termGuid
    #>
    [CmdletBinding(DefaultParameterSetName = 'SingleGlossary')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'SingleGlossary')]
        [object]$Glossary,

        [Parameter(Mandatory, ParameterSetName = 'BulkGlossary')]
        [object[]]$Glossaries,

        [Parameter(Mandatory, ParameterSetName = 'SingleCategory')]
        [object]$Category,

        [Parameter(Mandatory, ParameterSetName = 'BulkCategory')]
        [object[]]$Categories,

        [Parameter(Mandatory, ParameterSetName = 'SingleTerm')]
        [object]$Term,

        [Parameter(Mandatory, ParameterSetName = 'BulkTerm')]
        [object[]]$Terms,

        [Parameter(Mandatory, ParameterSetName = 'AssignedEntities')]
        [object[]]$AssignedEntities,

        [Parameter(Mandatory, ParameterSetName = 'AssignedEntities')]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$Guid,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    switch ($PSCmdlet.ParameterSetName) {
        'SingleGlossary'   { return Invoke-PurviewRequest -Resource 'glossary' -Method POST -Body $Glossary -Connection $Connection }
        'BulkGlossary'     { return Invoke-PurviewRequest -Resource 'glossary/import' -Method POST -Body $Glossaries -Connection $Connection }
        'SingleCategory'   { return Invoke-PurviewRequest -Resource 'glossary/category' -Method POST -Body $Category -Connection $Connection }
        'BulkCategory'     { return Invoke-PurviewRequest -Resource 'glossary/categories' -Method POST -Body $Categories -Connection $Connection }
        'SingleTerm'       { return Invoke-PurviewRequest -Resource 'glossary/term' -Method POST -Body $Term -Connection $Connection }
        'BulkTerm'         { return Invoke-PurviewRequest -Resource 'glossary/terms' -Method POST -Body $Terms -Connection $Connection }
        'AssignedEntities' { return Invoke-PurviewRequest -Resource "glossary/terms/$Guid/assignedEntities" -Method POST -Body $AssignedEntities -Connection $Connection }
    }
}
