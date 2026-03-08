function New-PurviewCollection {
    <#
    .SYNOPSIS
        Creates a new collection in the Purview account (PUT account/collections/{name}).
    .PARAMETER Name
        Unique internal name for the new collection (3-36 alphanumeric chars).
    .PARAMETER CollectionDef
        Hashtable with collection properties:
          friendlyName     – display name
          parentCollection – @{ referenceName = 'parentCollectionName' }
          description      – optional description
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        $col = @{
            friendlyName     = 'Finance'
            parentCollection = @{ referenceName = 'root' }
            description      = 'Finance department assets'
        }
        New-PurviewCollection -Name 'finance' -CollectionDef $col
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[a-zA-Z0-9]{3,36}$')]
        [string]$Name,

        [Parameter(Mandatory)]
        [object]$CollectionDef,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    return Invoke-PurviewRequest -Resource "collections/$Name" -Method PUT -Body $CollectionDef -ApiType Account -Connection $Connection
}
