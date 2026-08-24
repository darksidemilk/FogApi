using System.Collections;
using System.Management.Automation;

namespace FogApi;

/// <summary>
/// An <see cref="ArgumentTransformationAttribute"/> for the id-or-object contract.
/// </summary>
/// <remarks>
/// <para>
/// Every cmdlet that takes "which host" used to re-implement the same unwrapping
/// in its process block, against <c>$_</c>. That runs AFTER binding, so it could
/// not make the parameter itself accept an object -- which is why
/// <c>Get-FogHost -hostID $h | Get-FogHost</c> was rejected outright with "the
/// input object cannot be bound to any parameters". Doing the same work in a
/// transformation attribute happens DURING binding, so an object straight off
/// the pipeline binds to an id parameter and the body gets a plain id.
/// </para>
/// <para>Accepts, in this order:</para>
/// <list type="bullet">
///   <item>a number, or a string -- passed through as it arrived, because
///         callers pass both 5 and "5" today and the URI builder treats them
///         the same</item>
///   <item>a collection -- handed back whole, so the engine binds element by
///         element rather than stringifying the array into a URI</item>
///   <item>an object with an <c>id</c> property -- the FOG entity every getter
///         returns</item>
///   <item>anything else -- passed through untouched, so a -name string still
///         binds to a byName parameter set and nothing that worked stops</item>
/// </list>
/// <para>
/// Deliberately NOT a resolver: it does not call the API to turn a name into an
/// id. A transformation attribute runs during parameter binding, where a failure
/// surfaces as a binding error rather than the server's own message, and where a
/// round trip is invisible to the caller. Name resolution stays in the byName
/// parameter set, which can report what it did.
/// </para>
/// <para>
/// Named with the Attribute suffix on purpose. PowerShell appends it when
/// resolving an attribute name, so <c>[FogObjectRefTransform()]</c> in a .ps1
/// still resolves to this type, while C# using it as an attribute requires the
/// suffix. Naming it bare works from PowerShell and fails the C# convention.
/// </para>
/// </remarks>
public sealed class FogObjectRefTransformAttribute : ArgumentTransformationAttribute
{
    /// <inheritdoc/>
    public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
    {
        if (inputData is null)
        {
            return inputData!;
        }

        // PowerShell wraps pipeline input in a PSObject often enough that
        // unwrapping first keeps the rest of this simple.
        object item = inputData is PSObject pso ? pso.BaseObject : inputData;

        if (item is int or long or short or byte or double or decimal or float or string)
        {
            return inputData;
        }

        // A collection binds element by element. Note the string test above
        // comes first: string IS IEnumerable, and letting it fall through here
        // would bind a name one character at a time.
        if (item is IEnumerable)
        {
            return inputData;
        }

        PSPropertyInfo? id = PSObject.AsPSObject(inputData).Properties["id"];
        if (id?.Value is not null)
        {
            return id.Value;
        }

        // Not something this knows how to read. Returning it unchanged leaves
        // the decision to the parameter's own type and validation, which can
        // say something more useful than this attribute could.
        return inputData;
    }
}
