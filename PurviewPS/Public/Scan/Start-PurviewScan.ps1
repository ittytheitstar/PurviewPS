function Start-PurviewScan {
    <#
    .SYNOPSIS
        Triggers a scan run on a registered data source in Purview Scanning.
    .DESCRIPTION
        POST scan/datasources/{dataSourceName}/scans/{scanName}/runs/{runId}

        Generates a new GUID for the run ID automatically if -RunId is omitted.
    .PARAMETER DataSourceName
        Name of the registered data source.
    .PARAMETER ScanName
        Name of the scan to run.
    .PARAMETER RunId
        Optional GUID for the run.  A new GUID is generated if omitted.
    .PARAMETER ScanLevel
        Scan level: Full or Incremental (default: Full).
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Start-PurviewScan -DataSourceName 'AzureSqlDatabase_finance' -ScanName 'WeeklyFullScan'
    .EXAMPLE
        Start-PurviewScan -DataSourceName 'AzureSqlDatabase_finance' -ScanName 'IncrementalScan' -ScanLevel Incremental
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$DataSourceName,

        [Parameter(Mandatory)]
        [string]$ScanName,

        [string]$RunId = [System.Guid]::NewGuid().ToString(),

        [ValidateSet('Full', 'Incremental')]
        [string]$ScanLevel = 'Full',

        [Parameter()]
        [PSCustomObject]$Connection
    )

    if ($PSCmdlet.ShouldProcess("$DataSourceName/$ScanName", "Start $ScanLevel scan")) {
        $body = @{ scanLevel = $ScanLevel }
        return Invoke-PurviewRequest `
            -Resource "datasources/$DataSourceName/scans/$ScanName/runs/$RunId" `
            -Method   POST `
            -Body     $body `
            -ApiType  Scan `
            -Connection $Connection
    }
}
