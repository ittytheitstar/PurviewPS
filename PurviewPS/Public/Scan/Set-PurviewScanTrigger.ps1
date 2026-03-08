function Set-PurviewScanTrigger {
    <#
    .SYNOPSIS
        Creates or replaces the schedule trigger for a scan in Purview Scanning.
    .DESCRIPTION
        PUT scan/datasources/{dataSourceName}/scans/{scanName}/triggers/default
    .PARAMETER DataSourceName
        Name of the registered data source.
    .PARAMETER ScanName
        Name of the scan.
    .PARAMETER TriggerDef
        Hashtable with the trigger schedule (recurrence or once).
        Example: @{ properties = @{ recurrence = @{ frequency = 'Week'; interval = 1;
                   scheduleStartTime = '2024-01-01T00:00:00Z' } } }
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        $trigger = @{
            properties = @{
                recurrence = @{
                    frequency         = 'Week'
                    interval          = 1
                    scheduleStartTime = '2024-01-01T00:00:00Z'
                }
            }
        }
        Set-PurviewScanTrigger -DataSourceName 'AzureSqlDatabase_finance' -ScanName 'WeeklyFullScan' -TriggerDef $trigger
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DataSourceName,

        [Parameter(Mandatory)]
        [string]$ScanName,

        [Parameter(Mandatory)]
        [object]$TriggerDef,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    return Invoke-PurviewRequest `
        -Resource "datasources/$DataSourceName/scans/$ScanName/triggers/default" `
        -Method  PUT `
        -Body    $TriggerDef `
        -ApiType Scan `
        -Connection $Connection
}
