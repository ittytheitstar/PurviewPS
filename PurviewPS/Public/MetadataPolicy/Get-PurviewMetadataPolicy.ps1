function Get-PurviewMetadataPolicy {
    <#
    .SYNOPSIS
        Retrieves metadata access policies from the Purview policy store.
    .DESCRIPTION
        -PolicyId                       GET policystore/metadataPolicies/{policyId}
        -CollectionName                 GET policystore/metadataPolicies?collectionName={name}
        (default)                       GET policystore/metadataPolicies
    .PARAMETER PolicyId
        ID of a specific metadata policy to retrieve.
    .PARAMETER CollectionName
        Collection name filter; returns the policy scoped to that collection.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Get-PurviewMetadataPolicy
    .EXAMPLE
        Get-PurviewMetadataPolicy -CollectionName 'finance'
    .EXAMPLE
        Get-PurviewMetadataPolicy -PolicyId 'policy-abc-123'
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [string]$PolicyId,

        [Parameter(Mandatory, ParameterSetName = 'ByCollection')]
        [string]$CollectionName,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    switch ($PSCmdlet.ParameterSetName) {
        'All'          { return Invoke-PurviewRequest -Resource 'metadataPolicies' -ApiType Policy -Connection $Connection }
        'ById'         { return Invoke-PurviewRequest -Resource "metadataPolicies/$PolicyId" -ApiType Policy -Connection $Connection }
        'ByCollection' { return Invoke-PurviewRequest -Resource "metadataPolicies?collectionName=$([Uri]::EscapeDataString($CollectionName))" -ApiType Policy -Connection $Connection }
    }
}
