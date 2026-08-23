function Add-FogTypeName {
<#
.SYNOPSIS
Stamps a PSTypeName onto what a getter returns.

.DESCRIPTION
Type data attaches behaviour to a type NAME, and an object carries no name until
something puts one there. So a <Type> block, an Update-TypeData call and a
format file are all inert until this runs -- which is why the stamp is its own
phase and not a detail of the one that writes the type data.

Before this, exactly one cmdlet in the module stamped anything: Get-FogHost
inserted FogApi.Host by hand. Every other getter returned a bare PSCustomObject,
so Register-FogTypeData's display set, ToString, Refresh/Deploy/Cancel methods
and SysUuid property applied to host and nothing else.

The stamp is additive -- Insert(0, ...) in front of the existing type names
rather than replacing them -- so nothing that tests for PSCustomObject stops
working. Which is the whole reason FOG objects are modelled with type data
instead of classes: the server returns host with 39 fields where the schema
declares 30, and a class would have to drop the other nine or move them to a
catch-all, breaking every caller's property path invisibly. A type name asserts
nothing about fields, so nothing moves.

Passes the object straight through, so it wraps a return without changing it.
Collections are stamped element by element, because that is where the name has
to be for Format-Table to pick up a format definition.

.PARAMETER InputObject
What to stamp. Anything, including $null and collections.

.PARAMETER TypeName
The name to insert, e.g. FogApi.Printer.

.EXAMPLE
Add-FogTypeName -InputObject (Get-FogObject -type object -coreObject printer -IDofObject 1) -TypeName 'FogApi.Printer'

Returns the printer, carrying FogApi.Printer as its first type name.
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [AllowNull()]
        [Object]$InputObject,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$TypeName
    )

    process {
        if ($null -eq $InputObject) { return $InputObject }

        foreach ($item in @($InputObject)) {
            if ($null -eq $item) { continue }
            # A value type has no PSObject worth stamping, and a string would
            # pick the name up on every character of a collection.
            if ($item -is [string] -or $item -is [System.ValueType]) { continue }
            if ($item.PSObject.TypeNames[0] -ne $TypeName) {
                $item.PSObject.TypeNames.Insert(0, $TypeName)
            }
        }
        return $InputObject
    }
}
