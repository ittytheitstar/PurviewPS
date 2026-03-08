function Remove-PurviewDataSource {
    <#
    .SYNOPSIS
        Deletes a registered data source from Purview Scanning.
    .DESCRIPTION
        DELETE scan/datasources/{dataSourceName}
    .PARAMETER Name
        Name of the data source to delete.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Remove-PurviewDataSource -Name 'AzureSqlDatabase_finance'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    if ($PSCmdlet.ShouldProcess($Name, 'Delete data source')) {
        return Invoke-PurviewRequest -Resource "datasources/$Name" -Method DELETE -ApiType Scan -Connection $Connection
    }
}
