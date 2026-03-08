function Set-PurviewScanFilter {
    <#
    .SYNOPSIS
        Creates or replaces the custom scan filter for a scan in Purview Scanning.
    .DESCRIPTION
        PUT scan/datasources/{dataSourceName}/scans/{scanName}/filters/custom
    .PARAMETER DataSourceName
        Name of the registered data source.
    .PARAMETER ScanName
        Name of the scan.
    .PARAMETER FilterDef
        Hashtable with include/exclude path patterns (properties.include and
        properties.exclude arrays).
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        $filter = @{
            properties = @{
                include = @('schema1/%', 'schema2/%')
                exclude = @('schema1/tmp_%')
            }
        }
        Set-PurviewScanFilter -DataSourceName 'AzureSqlDatabase_finance' -ScanName 'FullScan' -FilterDef $filter
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DataSourceName,

        [Parameter(Mandatory)]
        [string]$ScanName,

        [Parameter(Mandatory)]
        [object]$FilterDef,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    return Invoke-PurviewRequest `
        -Resource "datasources/$DataSourceName/scans/$ScanName/filters/custom" `
        -Method  PUT `
        -Body    $FilterDef `
        -ApiType Scan `
        -Connection $Connection
}
