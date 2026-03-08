function Connect-Purview {
    <#
    .SYNOPSIS
        Establishes a connection to a Microsoft Purview account and stores it
        as the active module-level session.
    .DESCRIPTION
        Authenticates using a Service Principal (client_credentials flow via
        the Microsoft identity v2 endpoint) or a Managed Identity (Azure IMDS).
        The resulting connection object is stored in the module scope and is
        used automatically by all other PurviewPS cmdlets.

        Use -PassThru to capture the connection object for explicit -Connection
        parameter usage or multi-account scenarios.
    .PARAMETER AccountName
        The name of the Purview account (e.g. 'contoso-purview').
        Used to construct all REST endpoint base URLs.
    .PARAMETER TenantId
        Azure Active Directory tenant GUID.  Required for ServicePrincipal auth.
    .PARAMETER ClientId
        Application (client) GUID of the App Registration.
        Required for ServicePrincipal auth.
    .PARAMETER ClientSecret
        Client secret for the App Registration.
        Required for ServicePrincipal auth.
    .PARAMETER ManagedIdentityClientId
        Optional client ID for a User-Assigned Managed Identity.
        Omit to use the System-Assigned Managed Identity.
    .PARAMETER PassThru
        Returns the connection object to the pipeline instead of storing it
        silently.
    .EXAMPLE
        Connect-Purview -AccountName 'contoso-purview' `
            -TenantId     '00000000-0000-0000-0000-000000000000' `
            -ClientId     '00000000-0000-0000-0000-000000000000' `
            -ClientSecret 'my-secret'
    .EXAMPLE
        # Managed Identity (e.g. inside an Azure Function or Automation Runbook)
        Connect-Purview -AccountName 'contoso-purview' -ManagedIdentity
    .EXAMPLE
        # Multi-account: capture the connection explicitly
        $devConn  = Connect-Purview -AccountName 'dev-purview'  ... -PassThru
        $prodConn = Connect-Purview -AccountName 'prod-purview' ... -PassThru
        Get-PurviewEntity -Guid $id -Connection $devConn
    #>
    [CmdletBinding(DefaultParameterSetName = 'ServicePrincipal')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ServicePrincipal')]
        [Parameter(Mandatory, ParameterSetName = 'ManagedIdentity')]
        [ValidateNotNullOrEmpty()]
        [string]$AccountName,

        [Parameter(Mandatory, ParameterSetName = 'ServicePrincipal')]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$TenantId,

        [Parameter(Mandatory, ParameterSetName = 'ServicePrincipal')]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$ClientId,

        [Parameter(Mandatory, ParameterSetName = 'ServicePrincipal')]
        [string]$ClientSecret,

        [Parameter(ParameterSetName = 'ManagedIdentity')]
        [switch]$ManagedIdentity,

        [Parameter(ParameterSetName = 'ManagedIdentity')]
        [string]$ManagedIdentityClientId,

        [switch]$PassThru
    )

    $authMode = $PSCmdlet.ParameterSetName

    $connection = [PSCustomObject]@{
        PSTypeName   = 'PurviewPS.Connection'
        AccountName  = $AccountName
        TenantId     = if ($authMode -eq 'ServicePrincipal') { $TenantId } else { '' }
        ClientId     = if ($authMode -eq 'ServicePrincipal') { $ClientId } else { $ManagedIdentityClientId }
        ClientSecret = if ($authMode -eq 'ServicePrincipal') { $ClientSecret } else { '' }
        AuthMode     = $authMode
        AccessToken  = ''
        TokenExpiry  = [DateTime]::MinValue
    }

    # Fetch the initial token
    Update-PurviewToken -Connection $connection

    # Store as the active module connection
    $script:PurviewConnection = $connection

    Write-Verbose "Connected to Purview account '$AccountName' using $authMode."

    if ($PassThru) { return $connection }
}
