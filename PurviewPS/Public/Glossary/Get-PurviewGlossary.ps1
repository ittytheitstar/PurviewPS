function Get-PurviewGlossary {
    <#
    .SYNOPSIS
        Retrieves glossaries, categories, terms, and related objects from the
        Purview Data Map (Atlas v2 Glossary API).
    .DESCRIPTION
        Supported operations:

        (default)                  GET glossary               – list all glossaries
        -Guid                      GET glossary/{guid}         – single glossary
        -Guid -Detailed            GET glossary/{guid}/detailed
        -Guid -Categories          GET glossary/{guid}/categories
        -Guid -Categories -Headers GET glossary/{guid}/categories/headers
        -Guid -Terms               GET glossary/{guid}/terms
        -Guid -Terms -Headers      GET glossary/{guid}/terms/headers
        -Guid -Category            GET glossary/category/{guid}
        -Guid -Category -Related   GET glossary/category/{guid}/related
        -Guid -Category -Terms     GET glossary/category/{guid}/terms
        -Guid -Term                GET glossary/term/{guid}
        -Guid -Term -Related       GET glossary/terms/{guid}/related
        -Guid -Term -AssignedEntities  GET glossary/terms/{guid}/assignedEntities
        -ImportTemplate            GET glossary/import/template
    .PARAMETER Guid
        GUID of the glossary, category, or term.
    .PARAMETER Category
        Switch – target the category sub-resource.
    .PARAMETER Term
        Switch – target the term sub-resource.
    .PARAMETER Categories
        Switch – return the glossary's categories.
    .PARAMETER Terms
        Switch – return the glossary's terms or a category's terms.
    .PARAMETER Detailed
        Return the full extended info (categoryInfo + termInfo).
    .PARAMETER Headers
        Return header objects only (lighter payload) for categories or terms.
    .PARAMETER Related
        Return related categories/terms.
    .PARAMETER AssignedEntities
        Return entities assigned to a term.
    .PARAMETER ImportTemplate
        Download the CSV import template.
    .PARAMETER Limit
        Page size for list operations (default: 1000).
    .PARAMETER Offset
        Pagination offset (default: 0).
    .PARAMETER SortBy
        Sort field (default: name).
    .PARAMETER SortOrder
        ASC or DESC (default: ASC).
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Get-PurviewGlossary
    .EXAMPLE
        Get-PurviewGlossary -Guid $glossaryGuid -Terms
    .EXAMPLE
        Get-PurviewGlossary -Guid $termGuid -Term -AssignedEntities
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [Parameter(ParameterSetName = 'ByGuid')]
        [Parameter(ParameterSetName = 'Category')]
        [Parameter(ParameterSetName = 'Term')]
        [Parameter(ParameterSetName = 'GlossaryCategories')]
        [Parameter(ParameterSetName = 'GlossaryTerms')]
        [Parameter(ParameterSetName = 'GlossaryDetailed')]
        [Parameter(ParameterSetName = 'CategoryRelated')]
        [Parameter(ParameterSetName = 'CategoryTerms')]
        [Parameter(ParameterSetName = 'TermRelated')]
        [Parameter(ParameterSetName = 'TermAssignedEntities')]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$Guid,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All,

        [Parameter(Mandatory, ParameterSetName = 'Category')]
        [Parameter(Mandatory, ParameterSetName = 'CategoryRelated')]
        [Parameter(Mandatory, ParameterSetName = 'CategoryTerms')]
        [switch]$Category,

        [Parameter(Mandatory, ParameterSetName = 'Term')]
        [Parameter(Mandatory, ParameterSetName = 'TermRelated')]
        [Parameter(Mandatory, ParameterSetName = 'TermAssignedEntities')]
        [switch]$Term,

        [Parameter(Mandatory, ParameterSetName = 'GlossaryCategories')]
        [switch]$Categories,

        [Parameter(Mandatory, ParameterSetName = 'GlossaryTerms')]
        [switch]$Terms,

        [Parameter(Mandatory, ParameterSetName = 'GlossaryDetailed')]
        [switch]$Detailed,

        [Parameter(ParameterSetName = 'GlossaryCategories')]
        [Parameter(ParameterSetName = 'GlossaryTerms')]
        [switch]$Headers,

        [Parameter(Mandatory, ParameterSetName = 'CategoryRelated')]
        [Parameter(Mandatory, ParameterSetName = 'TermRelated')]
        [switch]$Related,

        [Parameter(Mandatory, ParameterSetName = 'TermAssignedEntities')]
        [switch]$AssignedEntities,

        [Parameter(Mandatory, ParameterSetName = 'ImportTemplate')]
        [switch]$ImportTemplate,

        [ValidateRange(1, 1000)]
        [int]$Limit = 1000,

        [ValidateRange(0, [int]::MaxValue)]
        [int]$Offset = 0,

        [string]$SortBy = 'name',

        [ValidateSet('ASC', 'DESC')]
        [string]$SortOrder = 'ASC',

        [Parameter()]
        [PSCustomObject]$Connection
    )

    $paging = "limit=$Limit&offset=$Offset&sort=$($SortOrder)"

    switch ($PSCmdlet.ParameterSetName) {
        'All'                  { return Invoke-PurviewRequest -Resource "glossary?$paging" -Connection $Connection }
        'ByGuid'               { return Invoke-PurviewRequest -Resource "glossary/$Guid" -Connection $Connection }
        'GlossaryDetailed'     { return Invoke-PurviewRequest -Resource "glossary/$Guid/detailed" -Connection $Connection }
        'GlossaryCategories'   {
            $sub = if ($Headers) { 'categories/headers' } else { 'categories' }
            return Invoke-PurviewRequest -Resource "glossary/$($Guid)/$($sub)?$paging" -Connection $Connection
        }
        'GlossaryTerms'        {
            $sub = if ($Headers) { 'terms/headers' } else { 'terms' }
            return Invoke-PurviewRequest -Resource "glossary/$($Guid)/$($sub)?$paging" -Connection $Connection
        }
        'Category'             { return Invoke-PurviewRequest -Resource "glossary/category/$Guid" -Connection $Connection }
        'CategoryRelated'      { return Invoke-PurviewRequest -Resource "glossary/category/$Guid/related" -Connection $Connection }
        'CategoryTerms'        { return Invoke-PurviewRequest -Resource "glossary/category/$Guid/terms?$paging" -Connection $Connection }
        'Term'                 { return Invoke-PurviewRequest -Resource "glossary/term/$Guid" -Connection $Connection }
        'TermRelated'          { return Invoke-PurviewRequest -Resource "glossary/terms/$Guid/related" -Connection $Connection }
        'TermAssignedEntities' { return Invoke-PurviewRequest -Resource "glossary/terms/$Guid/assignedEntities?$paging" -Connection $Connection }
        'ImportTemplate'       { return Invoke-PurviewRequest -Resource "glossary/import/template" -Connection $Connection }
    }
}
