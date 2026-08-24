using System.Dynamic;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace FogApi.Models;

/// <summary>
/// Base for every generated FOG entity.
/// </summary>
/// <remarks>
/// <para>
/// FOG's <c>OpenAPI::_entitySchema()</c> reflects a model's own
/// <c>$databaseFields</c>, its columns, while the route returns that entity
/// JOINED to its relations. host declares 33 columns and answers with more:
/// mac, primac, groups, snapins, inventory, task, fingerprint and nine others.
/// 80 such fields across 24 classes, and the document names them only in an
/// English sentence.
/// </para>
/// <para>
/// A plain class would drop them, or relocate them to an AdditionalData bag and
/// break every caller's property path. Deriving from <see cref="DynamicObject"/>
/// makes <c>$h.macs</c> and <c>$h.inventory.sysuuid</c> resolve for fields the
/// model never declared. That was measured on pwsh 7.6.4, including nested
/// access and Select-Object -- and measured NOT to work for
/// <c>IDictionary&lt;string,object&gt;</c>, which is what an off-the-shelf
/// generator would have produced.
/// </para>
/// <para>
/// Two things it does not buy: <c>Get-Member</c> does not list dynamic members
/// (though <c>Format-List *</c> does, via
/// <see cref="GetDynamicMemberNames"/>), and <c>ConvertTo-Json</c> silently
/// drops them -- which is why <see cref="ToJson"/> exists and why the generated
/// converter writes the bag back out.
/// </para>
/// </remarks>
public abstract class FogEntity : DynamicObject
{
    private readonly Dictionary<string, JsonNode?> _undeclared = new(StringComparer.OrdinalIgnoreCase);
    private readonly HashSet<string> _dirty = new(StringComparer.OrdinalIgnoreCase);

    // Map, FogClass, the dirty set and the undeclared names are all INTERNAL,
    // and that is about ConvertTo-Json rather than encapsulation. PowerShell's
    // serialiser walks public properties, so a public Map turned
    // `$o | ConvertTo-Json` into a dump of the field table and the entity's own
    // bookkeeping, with the actual data buried in the middle of it. Internal
    // keeps them reachable from the cmdlets and the converter -- everything
    // that needs them is in this assembly -- and out of the output.

    /// <summary>The fields this entity declares.</summary>
    internal abstract FogFieldMap Map { get; }

    /// <summary>The route class this entity belongs to, e.g. <c>printer</c>.</summary>
    internal abstract string FogClass { get; }

    // ---- undeclared fields --------------------------------------------------

    /// <inheritdoc/>
    public override bool TryGetMember(GetMemberBinder binder, out object? result)
    {
        if (!_undeclared.TryGetValue(binder.Name, out JsonNode? node))
        {
            result = null;
            return false;
        }
        // Converted on read rather than on store. The bag holds the JsonNode
        // FOG sent, because storing the PowerShell projection instead put
        // PSObjects in the graph -- and serialising one of those walks its
        // Members and OverloadDefinitions until System.Text.Json gives up with
        // "a possible object cycle was detected". ToJson threw on any entity
        // with a nested computed field, which on host is most of them.
        result = FogJson.ToPowerShell(node);
        return true;
    }

    /// <summary>
    /// Assigns an undeclared field, but only one the server actually sent.
    /// </summary>
    /// <remarks>
    /// Returning false for an unknown name is deliberate. PowerShell turns that
    /// into "The property 'desciption' cannot be found on this object", which is
    /// what a typo deserves. Accepting it would create a phantom field that
    /// silently never reaches the server.
    /// </remarks>
    public override bool TrySetMember(SetMemberBinder binder, object? value)
    {
        if (!_undeclared.ContainsKey(binder.Name)) { return false; }
        _undeclared[binder.Name] = value is null ? null : JsonSerializer.SerializeToNode(value, FogJson.Wire);
        _dirty.Add(binder.Name);
        return true;
    }

    /// <inheritdoc/>
    public override IEnumerable<string> GetDynamicMemberNames() => _undeclared.Keys;

    /// <summary>Names of the fields the server sent that the schema does not declare.</summary>
    /// <remarks>A method, not a property, so ConvertTo-Json does not emit it.</remarks>
    public string[] GetUndeclaredFieldNames() => _undeclared.Keys.ToArray();

    /// <summary>
    /// An undeclared field's value. <c>Get-Member</c> cannot see these, so this
    /// is the discoverable way to reach one.
    /// </summary>
    public object? Field(string name)
        => _undeclared.TryGetValue(name, out JsonNode? node) ? FogJson.ToPowerShell(node) : null;

    /// <summary>The raw node behind an undeclared field.</summary>
    internal JsonNode? FieldNode(string name)
        => _undeclared.TryGetValue(name, out JsonNode? node) ? node : null;

    /// <summary>Records a field the server sent that the schema does not declare.</summary>
    internal void AcceptUndeclared(string name, JsonNode? value) => _undeclared[name] = value;

    // ---- dirty tracking -----------------------------------------------------

    /// <summary>Assigns a declared field and remembers that it was assigned.</summary>
    protected void Set<T>(ref T store, T value, [CallerMemberName] string? name = null)
    {
        store = value;
        if (name is not null) { _dirty.Add(name); }
    }

    /// <summary>Fields assigned since this entity was materialised.</summary>
    /// <remarks>A method, not a property, so ConvertTo-Json does not emit it.</remarks>
    public string[] GetDirtyFields() => _dirty.ToArray();

    /// <summary>Forgets which fields were assigned.</summary>
    public void ClearDirty() => _dirty.Clear();

    /// <summary>
    /// The body for an update: only what was actually assigned.
    /// </summary>
    /// <remarks>
    /// FOG's edit route MERGES, so a field the body does not mention is left
    /// alone. Sending an unassigned field as "" therefore overwrites a real
    /// value with nothing -- data loss, not a cosmetic bug. The same rule the
    /// cmdlets apply through BoundParameters, for the object path.
    /// </remarks>
    public JsonObject ToPatch()
    {
        JsonObject body = new();
        foreach (string name in _dirty)
        {
            FogField? field = Map[name];
            if (field is null)
            {
                body[name] = FieldNode(name)?.DeepClone();
                continue;
            }
            if (field.ReadOnly) { continue; }
            body[field.Name] = field.ToWire(ReadDeclared(name));
        }
        return body;
    }

    /// <summary>Reads a declared field by name. Generated types override this.</summary>
    /// <remarks>
    /// A generated switch rather than reflection. There are 431 fields across
    /// 51 types and every list response walks all of them, so this is the hot
    /// path; and the emitter is writing the switch either way.
    /// </remarks>
    public virtual object? ReadDeclared(string name) => null;

    /// <summary>Assigns a declared field by name. Generated types override this.</summary>
    /// <returns>False when the type does not declare it, so the caller can bag it.</returns>
    public virtual bool SetDeclared(string name, JsonNode? value) => false;

    // ---- serialisation ------------------------------------------------------

    /// <summary>
    /// This entity as JSON, undeclared fields included.
    /// </summary>
    /// <remarks>
    /// <c>ConvertTo-Json</c> drops dynamic members -- measured -- so piping a
    /// host into it would lose 9 of its 39 fields. Use this instead when the
    /// whole object matters.
    /// </remarks>
    public string ToJson() => JsonSerializer.Serialize(this, GetType(), FogJson.Wire);

    /// <inheritdoc/>
    public override string ToString()
    {
        object? name = Map.Declares("name") ? ReadDeclared("name") : null;
        object? id = Map.Declares("id") ? ReadDeclared("id") : null;
        if (name is not null && id is not null) { return $"{name} ({id})"; }
        if (id is not null) { return $"{FogClass} {id}"; }
        return FogClass;
    }
}
