function New-PurviewDataSource {
    <#
    .SYNOPSIS
        Registers a new data source in Purview Scanning (PUT datasources/{name}).
    .DESCRIPTION
        Creates a data source registration using the supplied definition body.
        The body schema varies by source type (e.g., AzureSqlDatabase,
        AzureDataLakeStorage, SqlServerDatabase, etc.).
    .PARAMETER Name
        Unique name for the data source registration.
    .PARAMETER DataSourceDef
        Hashtable or PSCustomObject with the data source properties including
        kind, properties (serverEndpoint, collection, etc.).
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        $ds = @{
            kind       = 'AzureSqlDatabase'
            properties = @{
                serverEndpoint = 'myserver.database.windows.net'
                collection     = @{ referenceName = 'root' }
            }
        }
        New-PurviewDataSource -Name 'AzureSqlDatabase_finance' -DataSourceDef $ds
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [object]$DataSourceDef,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    return Invoke-PurviewRequest -Resource "datasources/$Name" -Method PUT -Body $DataSourceDef -ApiType Scan -Connection $Connection
}
