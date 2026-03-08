function Get-PurviewScan {
    <#
    .SYNOPSIS
        Retrieves scan definitions for a data source in Purview Scanning.
    .DESCRIPTION
        -DataSourceName -ScanName   GET scan/datasources/{ds}/scans/{scan}
        -DataSourceName             GET scan/datasources/{ds}/scans
    .PARAMETER DataSourceName
        Name of the registered data source.
    .PARAMETER ScanName
        Name of the specific scan.  Omit to list all scans for the data source.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Get-PurviewScan -DataSourceName 'AzureSqlDatabase_finance'
    .EXAMPLE
        Get-PurviewScan -DataSourceName 'AzureSqlDatabase_finance' -ScanName 'WeeklyFullScan'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DataSourceName,

        [Parameter()]
        [string]$ScanName,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    $resource = if ($ScanName) {
        "datasources/$DataSourceName/scans/$ScanName"
    } else {
        "datasources/$DataSourceName/scans"
    }

    return Invoke-PurviewRequest -Resource $resource -ApiType Scan -Connection $Connection
}
