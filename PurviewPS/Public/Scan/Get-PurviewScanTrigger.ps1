function Get-PurviewScanTrigger {
    <#
    .SYNOPSIS
        Retrieves the schedule trigger for a scan in Purview Scanning.
    .DESCRIPTION
        GET scan/datasources/{dataSourceName}/scans/{scanName}/triggers/default
    .PARAMETER DataSourceName
        Name of the registered data source.
    .PARAMETER ScanName
        Name of the scan.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Get-PurviewScanTrigger -DataSourceName 'AzureSqlDatabase_finance' -ScanName 'WeeklyFullScan'
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
        -Resource "datasources/$DataSourceName/scans/$ScanName/triggers/default" `
        -ApiType  Scan `
        -Connection $Connection
}
