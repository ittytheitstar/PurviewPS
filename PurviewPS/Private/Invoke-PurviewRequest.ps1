function Invoke-PurviewRequest {
    <#
    .SYNOPSIS
        Internal HTTP helper that dispatches requests to Purview REST endpoints.
    .DESCRIPTION
        Builds the correct base URL for each API surface, handles token refresh
        on 401 responses, serialises the body to JSON when needed, and provides
        consistent error messages.

        ApiType routing:
          Atlas   -> https://<account>.purview.azure.com/catalog/api/atlas/v2
          DataMap -> https://<account>.purview.azure.com/datamap/api/atlas/v2
          Scan    -> https://<account>.purview.azure.com/scan
          Account -> https://<account>.purview.azure.com/account
          Policy  -> https://<account>.purview.azure.com/policystore
    #>
    [CmdletBinding()]
    param(
        # Path after the base URL (e.g. "entity/guid/abc123")
        [Parameter(Mandatory)]
        [string]$Resource,

        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string]$Method = 'GET',

        # Object or already-serialised JSON string
        [Parameter()]
        $Body,

        [ValidateSet('Atlas', 'DataMap', 'Scan', 'Account', 'Policy')]
        [string]$ApiType = 'Atlas',

        # Override the api-version query parameter for Scan/Account/Policy endpoints
        [string]$ApiVersion,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    $conn = Get-PurviewConnectionOrThrow -Connection $Connection

    # Ensure we have a valid (non-expired) token
    if (-not $conn.AccessToken -or $conn.TokenExpiry -le (Get-Date).AddMinutes(5)) {
        Update-PurviewToken -Connection $conn
    }

    # ── Build URL ────────────────────────────────────────────────────────────
    $accountName = $conn.AccountName
    $baseUrl = switch ($ApiType) {
        'Atlas'   { "https://$accountName.purview.azure.com/catalog/api/atlas/v2" }
        'DataMap' { "https://$accountName.purview.azure.com/datamap/api/atlas/v2" }
        'Scan'    { "https://$accountName.purview.azure.com/scan" }
        'Account' { "https://$accountName.purview.azure.com/account" }
        'Policy'  { "https://$accountName.purview.azure.com/policystore" }
    }

    $url = "$baseUrl/$Resource".TrimEnd('/')

    # Append api-version for non-Atlas endpoints
    if ($ApiType -in 'Scan', 'Account', 'Policy') {
        $defaultVersions = @{
            'Scan'    = '2023-09-01'
            'Account' = '2023-09-01'
            'Policy'  = '2021-07-01-preview'
        }
        $ver = if ($ApiVersion) { $ApiVersion } else { $defaultVersions[$ApiType] }
        $url += if ($url -like '*?*') { "&api-version=$ver" } else { "?api-version=$ver" }
    }

    # ── Build request parameters ─────────────────────────────────────────────
    $headers = @{
        'Authorization' = "Bearer $($conn.AccessToken)"
        'Content-Type'  = 'application/json'
        'Accept'        = 'application/json'
    }

    $invokeParams = @{
        Uri         = $url
        Method      = $Method
        Headers     = $headers
        ErrorAction = 'Stop'
    }

    if ($null -ne $Body) {
        $invokeParams['Body'] = if ($Body -is [string]) {
            $Body
        } else {
            ConvertTo-Json $Body -Depth 20 -Compress
        }
    }

    # ── Execute (with automatic token refresh on 401) ─────────────────────────
    try {
        Write-Verbose "[$Method] $url"
        Invoke-RestMethod @invokeParams
    }
    catch {
        $statusCode = $null
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }

        if ($statusCode -eq 401) {
            Write-Verbose "Received 401 – refreshing token and retrying."
            Update-PurviewToken -Connection $conn
            $invokeParams.Headers['Authorization'] = "Bearer $($conn.AccessToken)"
            Invoke-RestMethod @invokeParams
        }
        else {
            # Attempt to extract a meaningful error message from the response body
            $errorBody = $null
            if ($_.ErrorDetails.Message) {
                try { $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json } catch {}
            }

            $msg = if ($errorBody -and $errorBody.error.message) {
                "[$($errorBody.error.code)] $($errorBody.error.message)"
            } elseif ($errorBody -and $errorBody.errorMessage) {
                $errorBody.errorMessage
            } else {
                $_.Exception.Message
            }

            throw "PurviewPS Error (HTTP $statusCode): $msg"
        }
    }
}
