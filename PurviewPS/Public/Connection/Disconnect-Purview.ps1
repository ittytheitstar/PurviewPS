function Disconnect-Purview {
    <#
    .SYNOPSIS
        Clears the active Purview connection from the module session.
    .DESCRIPTION
        Removes the connection stored by Connect-Purview.  After calling this
        function, all PurviewPS cmdlets will require an explicit -Connection
        parameter until Connect-Purview is called again.
    .EXAMPLE
        Disconnect-Purview
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess('PurviewPS module connection', 'Disconnect')) {
        $script:PurviewConnection = $null
        Write-Verbose "Disconnected from Purview."
    }
}
