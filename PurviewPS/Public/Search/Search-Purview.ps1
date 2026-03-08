function Search-Purview {
    <#
    .SYNOPSIS
        Searches, suggests, or autocompletes terms across the Purview Data Map.
    .DESCRIPTION
        Wraps three discovery endpoints:

        -SearchRequest       POST search/query        (advanced full-text search)
        -SuggestRequest      POST search/suggest      (suggested results)
        -AutoCompleteRequest POST search/autocomplete (keyword completion)
    .PARAMETER SearchRequest
        A SearchRequest object or hashtable with keywords, filters, facets,
        limit, and offset.
    .PARAMETER SuggestRequest
        A SuggestRequest object or hashtable with keywords, limit, and filter.
    .PARAMETER AutoCompleteRequest
        An AutoCompleteRequest object or hashtable with keyword and limit.
    .PARAMETER Connection
        Optional explicit connection object.
    .OUTPUTS
        AdvancedSearchResult | SuggestResult | AutocompleteResult
    .EXAMPLE
        $req = [SearchRequest]::new()
        $req.keywords = 'customer'
        $req.limit    = 25
        Search-Purview -SearchRequest $req
    .EXAMPLE
        Search-Purview -SearchRequest @{ keywords = 'sales'; limit = 10 }
    .EXAMPLE
        Search-Purview -SuggestRequest @{ keywords = 'rev'; limit = 5 }
    .EXAMPLE
        Search-Purview -AutoCompleteRequest @{ keyword = 'cust'; limit = 10 }
    #>
    [CmdletBinding(DefaultParameterSetName = 'Search')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Search')]
        [object]$SearchRequest,

        [Parameter(Mandatory, ParameterSetName = 'Suggest')]
        [object]$SuggestRequest,

        [Parameter(Mandatory, ParameterSetName = 'AutoComplete')]
        [object]$AutoCompleteRequest,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    switch ($PSCmdlet.ParameterSetName) {
        'Search' {
            return Invoke-PurviewRequest -Resource 'search/query' -Method POST -Body $SearchRequest -Connection $Connection
        }
        'Suggest' {
            return Invoke-PurviewRequest -Resource 'search/suggest' -Method POST -Body $SuggestRequest -Connection $Connection
        }
        'AutoComplete' {
            return Invoke-PurviewRequest -Resource 'search/autocomplete' -Method POST -Body $AutoCompleteRequest -Connection $Connection
        }
    }
}
