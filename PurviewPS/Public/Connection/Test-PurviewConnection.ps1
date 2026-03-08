function Test-PurviewConnection {
    <#
    .SYNOPSIS
        Tests whether a valid, non-expired Purview connection exists.
    .DESCRIPTION
        Returns $true if a connection is active and the cached token has not
        yet expired (with a 5-minute safety margin).  Returns $false otherwise.
        Pass -Connection to test a specific connection object.
    .PARAMETER Connection
        An explicit connection object returned by Connect-Purview -PassThru.
        If omitted, the module-level active connection is tested.
    .OUTPUTS
        [bool]
    .EXAMPLE
        if (-not (Test-PurviewConnection)) { Connect-Purview ... }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [PSCustomObject]$Connection
    )

    $conn = if ($Connection) { $Connection } else { $script:PurviewConnection }

    if ($null -eq $conn) { return $false }

    return ($conn.AccessToken -and $conn.TokenExpiry -gt (Get-Date).AddMinutes(5))
}
