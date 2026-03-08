function Get-PurviewScanFilter {
    <#
    .SYNOPSIS
        Retrieves the custom scan filter for a scan in Purview Scanning.
    .DESCRIPTION
        GET scan/datasources/{dataSourceName}/scans/{scanName}/filters/custom
    .PARAMETER DataSourceName
        Name of the registered data source.
    .PARAMETER ScanName
        Name of the scan.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Get-PurviewScanFilter -DataSourceName 'AzureSqlDatabase_finance' -ScanName 'FullScan'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DataSourceName,

        [Parameter(Mandatory)]
        [string]$ScanName,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    return Invoke-PurviewRequest `
        -Resource "datasources/$DataSourceName/scans/$ScanName/filters/custom" `
        -ApiType  Scan `
        -Connection $Connection
}
