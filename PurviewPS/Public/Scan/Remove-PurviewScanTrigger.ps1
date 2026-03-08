function Remove-PurviewScanTrigger {
    <#
    .SYNOPSIS
        Deletes the schedule trigger for a scan in Purview Scanning.
    .DESCRIPTION
        DELETE scan/datasources/{dataSourceName}/scans/{scanName}/triggers/default
    .PARAMETER DataSourceName
        Name of the registered data source.
    .PARAMETER ScanName
        Name of the scan.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Remove-PurviewScanTrigger -DataSourceName 'AzureSqlDatabase_finance' -ScanName 'WeeklyFullScan'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$DataSourceName,

        [Parameter(Mandatory)]
        [string]$ScanName,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    if ($PSCmdlet.ShouldProcess("$DataSourceName/$ScanName", 'Delete scan trigger')) {
        return Invoke-PurviewRequest `
            -Resource "datasources/$DataSourceName/scans/$ScanName/triggers/default" `
            -Method  DELETE `
            -ApiType Scan `
            -Connection $Connection
    }
}
