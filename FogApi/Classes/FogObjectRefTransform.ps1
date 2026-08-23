<#
An ArgumentTransformationAttribute for the id-or-object-or-name contract.

Every cmdlet that takes "which host" has re-implemented the same unwrapping, and
the hand-written ones did it in the process block against $_ :

    if ($null -ne $_) { $fogHost = $_; $hostId = $fogHost.id }
    if ($null -ne $hostIdNum) { $hostId = $hostIdNum }
    if ($null -ne $fogHostObject) { $fogHost = $fogHostObject; $hostId = $fogHost.id }
    if ($null -eq $hostId) { $hostId = $fogHost.id }

That runs after binding, so it cannot make the parameter itself accept an
object, which is why Get-FogHost rejected `Get-FogHost -hostID $h | Get-FogHost`
outright with "the input object cannot be bound to any parameters". Doing the
same work in a transformation attribute happens DURING binding, so an object
straight off the pipeline binds to an id parameter and the process block gets a
plain id.

    [FogObjectRefTransform()]
    [Object]$id

Accepts, in this order:
  * a number, or a string of digits -- passed through as-is
  * an object with an .id property -- the FOG entity every getter returns
  * an object with a .PSObject 'id' NoteProperty reached through -expand
  * anything else -- passed through untouched, so a -name string still binds
    to a byName parameter set and nothing that used to work stops working

Deliberately NOT a resolver: it does not call the API to turn a name into an id.
A transformation attribute runs during parameter binding, where a failure
surfaces as a binding error rather than the server's own message, and where a
round trip is invisible to the caller. Name resolution stays in the byName
parameter set, which can report what it did.

This is a class used AS an attribute, which is a different thing from a type
literal passed as an argument TO an attribute. The latter -- [OutputType([X])],
[ValidateSet([X])] -- does not resolve in a dot-sourced module and poisons the
whole function. Attribute instantiation resolves fine; measured, and recorded in
CONTEXT-typed-objects-plan.md.
#>
class FogObjectRefTransform : System.Management.Automation.ArgumentTransformationAttribute {

    [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object]$inputData) {
        if ($null -eq $inputData) { return $inputData }

        # PowerShell wraps pipeline input in a PSObject often enough that
        # unwrapping first keeps the rest of this simple.
        $item = $inputData
        if ($item -is [System.Management.Automation.PSObject]) { $item = $item.BaseObject }

        # An id already. Left exactly as it arrived -- callers pass both 5 and
        # "5" today and the URI builder treats them the same.
        if ($item -is [int] -or $item -is [long] -or $item -is [double] -or $item -is [decimal]) { return $inputData }
        if ($item -is [string]) { return $inputData }

        # A collection binds element by element, so handing it back whole lets
        # the engine do that rather than stringifying the array into a URI.
        if ($item -is [System.Collections.IEnumerable]) { return $inputData }

        $idProperty = $inputData.PSObject.Properties['id']
        if ($null -ne $idProperty -and $null -ne $idProperty.Value) { return $idProperty.Value }

        # Not something this knows how to read. Returning it unchanged leaves
        # the decision to the parameter's own type and validation, which can say
        # something more useful than this attribute could.
        return $inputData
    }
}
