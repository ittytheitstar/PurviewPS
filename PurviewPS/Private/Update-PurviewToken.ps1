function Update-PurviewToken {
    <#
    .SYNOPSIS
        Acquires or refreshes the OAuth 2.0 bearer token on a connection object.
    .DESCRIPTION
        Supports Service Principal (client_credentials) and System/User Assigned
        Managed Identity authentication. Updates AccessToken and TokenExpiry
        in-place on the supplied connection object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Connection
    )

    switch ($Connection.AuthMode) {

        'ServicePrincipal' {
            $tokenUrl = "https://login.microsoftonline.com/$($Connection.TenantId)/oauth2/v2.0/token"

            $body = @{
                grant_type    = 'client_credentials'
                client_id     = $Connection.ClientId
                client_secret = $Connection.ClientSecret
                scope         = 'https://purview.azure.net/.default'
            }

            try {
                $response = Invoke-RestMethod `
                    -Uri         $tokenUrl `
                    -Method      POST `
                    -ContentType 'application/x-www-form-urlencoded' `
                    -Body        $body `
                    -ErrorAction Stop

                $Connection.AccessToken = $response.access_token
                $Connection.TokenExpiry = (Get-Date).AddSeconds(
                    [int]$response.expires_in - 60
                )
                Write-Verbose "Token acquired for Service Principal '$($Connection.ClientId)'."
            }
            catch {
                throw "Failed to acquire Purview token: $($_.Exception.Message)"
            }
        }

        'ManagedIdentity' {
            # Azure Instance Metadata Service (IMDS) endpoint
            $imdsUrl = 'http://169.254.169.254/metadata/identity/oauth2/token'

            $queryParams = @{
                'api-version' = '2018-02-01'
                'resource'    = 'https://purview.azure.net/'
            }
            if ($Connection.ClientId) {
                $queryParams['client_id'] = $Connection.ClientId
            }

            $qs  = ($queryParams.GetEnumerator() |
                    ForEach-Object { "$($_.Key)=$([Uri]::EscapeDataString($_.Value))" }) -join '&'
            $url = "${imdsUrl}?${qs}"

            try {
                $response = Invoke-RestMethod `
                    -Uri     $url `
                    -Method  GET `
                    -Headers @{ Metadata = 'true' } `
                    -ErrorAction Stop

                $Connection.AccessToken = $response.access_token
                $Connection.TokenExpiry = (Get-Date).AddSeconds(
                    [int]$response.expires_in - 60
                )
                Write-Verbose "Managed Identity token acquired."
            }
            catch {
                throw "Failed to acquire managed identity token: $($_.Exception.Message)"
            }
        }

        default {
            throw "Unsupported AuthMode '$($Connection.AuthMode)'. " +
                  "Valid values: ServicePrincipal, ManagedIdentity."
        }
    }
}
