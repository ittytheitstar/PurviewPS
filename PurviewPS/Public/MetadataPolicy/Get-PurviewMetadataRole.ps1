function Get-PurviewMetadataRole {
    <#
    .SYNOPSIS
        Lists available metadata roles from the Purview policy store.
    .DESCRIPTION
        GET policystore/metadataRoles

        Returns all built-in and custom metadata roles that can be referenced
        when constructing or updating metadata policies.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        Get-PurviewMetadataRole
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [PSCustomObject]$Connection
    )

    return Invoke-PurviewRequest -Resource 'metadataRoles' -ApiType Policy -Connection $Connection
}
