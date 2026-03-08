function Set-PurviewMetadataPolicy {
    <#
    .SYNOPSIS
        Updates a metadata access policy in the Purview policy store (PUT policystore/metadataPolicies/{id}).
    .PARAMETER PolicyId
        ID of the metadata policy to update.
    .PARAMETER PolicyDef
        Updated policy body (MetadataPolicy or equivalent hashtable).
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        $policy = Get-PurviewMetadataPolicy -CollectionName 'finance'
        # ... modify $policy.properties.attributeRules as needed ...
        Set-PurviewMetadataPolicy -PolicyId $policy.id -PolicyDef $policy
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PolicyId,

        [Parameter(Mandatory)]
        [object]$PolicyDef,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    return Invoke-PurviewRequest -Resource "metadataPolicies/$PolicyId" -Method PUT -Body $PolicyDef -ApiType Policy -Connection $Connection
}
