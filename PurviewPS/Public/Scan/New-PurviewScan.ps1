function New-PurviewScan {
    <#
    .SYNOPSIS
        Creates or updates a scan definition for a data source (PUT scan/datasources/{ds}/scans/{scan}).
    .PARAMETER DataSourceName
        Name of the registered data source.
    .PARAMETER ScanName
        Name to assign to this scan.
    .PARAMETER ScanDef
        Hashtable or object containing the scan configuration (kind, scanRulesetName,
        collection, credential, etc.).
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        $scan = @{
            kind             = 'AzureSqlDatabaseMsi'
            properties       = @{
                databaseName     = 'FinanceDB'
                scanRulesetName  = 'AzureSqlDatabase'
                scanRulesetType  = 'System'
                collection       = @{ referenceName = 'finance-collection' }
            }
        }
        New-PurviewScan -DataSourceName 'AzureSqlDatabase_finance' -ScanName 'FullScan' -ScanDef $scan
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DataSourceName,

        [Parameter(Mandatory)]
        [string]$ScanName,

        [Parameter(Mandatory)]
        [object]$ScanDef,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    return Invoke-PurviewRequest -Resource "datasources/$DataSourceName/scans/$ScanName" -Method PUT -Body $ScanDef -ApiType Scan -Connection $Connection
}
