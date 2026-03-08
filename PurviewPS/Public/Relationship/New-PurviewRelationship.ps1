function New-PurviewRelationship {
    <#
    .SYNOPSIS
        Creates a new relationship between two entities in the Purview Data Map.
    .DESCRIPTION
        POST relationship
    .PARAMETER Relationship
        An AtlasRelationship object or equivalent hashtable describing the
        relationship to create.
    .PARAMETER Connection
        Optional explicit connection object.
    .EXAMPLE
        $rel = @{
            typeName   = 'AtlasGlossarySemanticAssignment'
            end1       = @{ guid = $termGuid;   typeName = 'AtlasGlossaryTerm' }
            end2       = @{ guid = $entityGuid; typeName = 'DataSet' }
        }
        New-PurviewRelationship -Relationship $rel
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Relationship,

        [Parameter()]
        [PSCustomObject]$Connection
    )

    return Invoke-PurviewRequest -Resource 'relationship' -Method POST -Body $Relationship -Connection $Connection
}
