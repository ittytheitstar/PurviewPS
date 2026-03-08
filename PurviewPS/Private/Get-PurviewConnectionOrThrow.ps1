function Get-PurviewConnectionOrThrow {
    <#
    .SYNOPSIS
        Returns the active Purview connection, throwing if none is available.
    .DESCRIPTION
        Internal helper used by all public API functions. Returns the
        -Connection parameter if provided, otherwise falls back to the
        module-scope $script:PurviewConnection set by Connect-Purview.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [AllowNull()]
        [PSCustomObject]$Connection
    )

    if ($Connection) { return $Connection }

    if ($script:PurviewConnection) { return $script:PurviewConnection }

    throw "No active Purview connection found. Run Connect-Purview first, " +
          "or supply a -Connection parameter."
}
