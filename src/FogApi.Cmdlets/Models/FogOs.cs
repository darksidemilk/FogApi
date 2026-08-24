using System.Text.Json.Nodes;
using System.Text.Json.Serialization;

namespace FogApi.Models;

/// <summary>
/// An operating system definition, from the <c>os</c> table.
/// </summary>
/// <remarks>
/// The second hand-written model, and the smallest class FOG has: three fields,
/// no computed ones. It exists to prove the L1 shapes against a class whose
/// write routes actually answer -- printer's create and get-by-id return 404 on
/// the dev server despite the document declaring both.
/// <para>
/// Written the way the emitter will write it, from <c>schemas.os</c>.
/// </para>
/// </remarks>
[JsonConverter(typeof(FogEntityConverter<FogOs>))]
public sealed class FogOs : FogEntity
{
    /// <summary>The fields FOG declares for an os.</summary>
    public static readonly FogFieldMap FieldMap = new(
        new FogField("id", "osID", FogWire.Int, ReadOnly: true),
        new FogField("name", "osName", FogWire.String, MaxLength: 30),
        new FogField("description", "osDescription", FogWire.String));

    /// <inheritdoc/>
    internal override FogFieldMap Map => FieldMap;

    /// <inheritdoc/>
    internal override string FogClass => "os";

    private long? _id;
    /// <summary>Primary key. <c>osID</c>.</summary>
    public long? id { get => _id; set => Set(ref _id, value); }

    private string? _name;
    /// <summary><c>osName</c>, varchar(30).</summary>
    public string? name { get => _name; set => Set(ref _name, value); }

    private string? _description;
    /// <summary><c>osDescription</c>.</summary>
    public string? description { get => _description; set => Set(ref _description, value); }

    /// <inheritdoc/>
    public override object? ReadDeclared(string field) => field.ToLowerInvariant() switch
    {
        "id" => id,
        "name" => name,
        "description" => description,
        _ => null,
    };

    /// <inheritdoc/>
    public override bool SetDeclared(string field, JsonNode? value)
    {
        switch (field.ToLowerInvariant())
        {
            case "id": id = FogRead.Int(value); return true;
            case "name": name = FogRead.String(value); return true;
            case "description": description = FogRead.String(value); return true;
            default: return false;
        }
    }
}
