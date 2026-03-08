function Stop-PurviewScan {
    <#
    .SYNOPSIS
        Cancels an in-progress scan run in Purview Scanning.
    .DESCRIPTION
        POST scan/datasources/{dataSourceName}/scans/{scanName}/runs/{runId}/:cancel
    .PARAMETER DataSourceName
        Name of the registered data source.
    .PARAMETER ScanName
        Name of the scan.
    .PARAMETER RunId
        GUID of the scan run to cancel.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Stop-PurviewScan -DataSourceName 'AzureSqlDatabase_finance' -ScanName 'FullScan' -RunId $runId
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$DataSourceName,

        [Parameter(Mandatory)]
        [string]$ScanName,

        [Parameter(Mandatory)]
        [string]$RunId,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    if ($PSCmdlet.ShouldProcess("$DataSourceName/$ScanName/$RunId", 'Cancel scan run')) {
        return Invoke-PurviewRequest `
            -Resource "datasources/$DataSourceName/scans/$ScanName/runs/$RunId/:cancel" `
            -Method   POST `
            -ApiType  Scan `
            -Connection $Connection
    }
}
