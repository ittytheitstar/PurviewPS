function Get-PurviewDataSource {
    <#
    .SYNOPSIS
        Retrieves one or all data sources registered in Purview Scanning.
    .DESCRIPTION
        -Name    GET scan/datasources/{dataSourceName}
        (default) GET scan/datasources
    .PARAMETER Name
        Name of the data source to retrieve.  Omit to list all data sources.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Get-PurviewDataSource
    .EXAMPLE
        Get-PurviewDataSource -Name 'AzureSqlDatabase_finance'
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$Name,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    $resource = if ($Name) { "datasources/$Name" } else { 'datasources' }
    return Invoke-PurviewRequest -Resource $resource -ApiType Scan -Connection $Connection
}
