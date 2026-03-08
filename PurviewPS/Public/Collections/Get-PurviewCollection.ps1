function Get-PurviewCollection {
    <#
    .SYNOPSIS
        Retrieves one or all collections from the Purview account.
    .DESCRIPTION
        -Name                   GET account/collections/{collectionName}
        (default)               GET account/collections
        -Name -ChildNames       GET account/collections/{name}/childcollectionnames
        -Name -Paths            GET account/collections/{name}/getpaths
    .PARAMETER Name
        Collection name (friendly name or internal name).
        Omit to list all collections.
    .PARAMETER ChildNames
        Return only child collection names for the specified collection.
    .PARAMETER Paths
        Return the parent path hierarchy for the specified collection.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Get-PurviewCollection
    .EXAMPLE
        Get-PurviewCollection -Name 'finance'
    .EXAMPLE
        Get-PurviewCollection -Name 'finance' -ChildNames
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ChildNames')]
        [Parameter(ParameterSetName = 'Paths')]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'ChildNames')]
        [switch]$ChildNames,

        [Parameter(Mandatory, ParameterSetName = 'Paths')]
        [switch]$Paths,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    switch ($PSCmdlet.ParameterSetName) {
        'All'        { return Invoke-PurviewRequest -Resource 'collections' -ApiType Account -Connection $Connection }
        'ByName'     { return Invoke-PurviewRequest -Resource "collections/$Name" -ApiType Account -Connection $Connection }
        'ChildNames' { return Invoke-PurviewRequest -Resource "collections/$Name/childcollectionnames" -ApiType Account -Connection $Connection }
        'Paths'      { return Invoke-PurviewRequest -Resource "collections/$Name/getpaths" -ApiType Account -Connection $Connection }
    }
}
