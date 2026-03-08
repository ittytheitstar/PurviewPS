function Set-PurviewScan {
    <#
    .SYNOPSIS
        Updates an existing scan definition on a registered data source (PUT scan/datasources/{ds}/scans/{scan}).
    .DESCRIPTION
        Uses the same PUT endpoint as New-PurviewScan; provided as a
        semantically distinct cmdlet for the update case.
    .PARAMETER DataSourceName
        Name of the registered data source.
    .PARAMETER ScanName
        Name of the scan to update.
    .PARAMETER ScanDef
        Updated scan body (kind + properties hashtable).
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        $scan = Get-PurviewScan -DataSourceName 'SqlFinance' -ScanName 'FullScan'
        $scan.properties.scanRulesetName = 'Custom'
        Set-PurviewScan -DataSourceName 'SqlFinance' -ScanName 'FullScan' -ScanDef $scan
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

    return Invoke-PurviewRequest `
        -Resource "datasources/$DataSourceName/scans/$ScanName" `
        -Method  PUT `
        -Body    $ScanDef `
        -ApiType Scan `
        -Connection $Connection
}
