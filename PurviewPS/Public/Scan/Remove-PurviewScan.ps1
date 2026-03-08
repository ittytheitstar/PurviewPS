function Remove-PurviewScan {
    <#
    .SYNOPSIS
        Deletes a scan definition from a data source in Purview Scanning.
    .DESCRIPTION
        DELETE scan/datasources/{dataSourceName}/scans/{scanName}
    .PARAMETER DataSourceName
        Name of the registered data source.
    .PARAMETER ScanName
        Name of the scan to delete.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Remove-PurviewScan -DataSourceName 'AzureSqlDatabase_finance' -ScanName 'OldScan'
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

    if ($PSCmdlet.ShouldProcess("$DataSourceName/$ScanName", 'Delete scan')) {
        return Invoke-PurviewRequest -Resource "datasources/$DataSourceName/scans/$ScanName" -Method DELETE -ApiType Scan -Connection $Connection
    }
}
