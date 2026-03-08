function Get-PurviewConnection {
    <#
    .SYNOPSIS
        Returns the currently active Purview connection.
    .DESCRIPTION
        Returns the PSCustomObject set by Connect-Purview, or $null if no
        connection is active.  Use Test-PurviewConnection to get a boolean
        result instead.
    .OUTPUTS
        PSCustomObject (PurviewPS.Connection) or $null
    .EXAMPLE
        $conn = Get-PurviewConnection
        $conn.AccountName
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    return $script:PurviewConnection
}
