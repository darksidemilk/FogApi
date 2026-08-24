using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization;

namespace FogApi.Models;

/// <summary>
/// Reads and writes a <see cref="FogEntity"/>, keeping the fields FOG sends
/// that the schema does not declare.
/// </summary>
/// <remarks>
/// <para>
/// [JsonExtensionData] would nearly do this, but it has to be a public property,
/// and a public dictionary shows up in Format-List * as
/// <c>Extra : {[macs, System.Object[]], ...}</c> next to the real fields. A
/// converter keeps the bag private and the display clean.
/// </para>
/// <para>
/// Writing the bag back out is the point. ConvertTo-Json drops dynamic members
/// -- measured -- so without this a round trip through JSON would lose 9 of a
/// host's 39 fields.
/// </para>
/// </remarks>
/// <typeparam name="T">The entity type.</typeparam>
public sealed class FogEntityConverter<T> : JsonConverter<T> where T : FogEntity, new()
{
    /// <inheritdoc/>
    public override T Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        JsonNode? node = JsonNode.Parse(ref reader);
        if (node is not JsonObject obj)
        {
            throw new JsonException($"expected a JSON object for {typeof(T).Name}, got {node?.GetValueKind()}");
        }

        T entity = new();
        foreach (KeyValuePair<string, JsonNode?> pair in obj)
        {
            if (entity.SetDeclared(pair.Key, pair.Value)) { continue; }
            entity.AcceptUndeclared(pair.Key, pair.Value?.DeepClone());
        }

        // Deserialising is not a user edit. Without this every field would look
        // assigned and ToPatch would send the whole object back on the first
        // update -- including values the caller never touched.
        entity.ClearDirty();
        return entity;
    }

    /// <inheritdoc/>
    public override void Write(Utf8JsonWriter writer, T value, JsonSerializerOptions options)
    {
        writer.WriteStartObject();

        foreach (FogField field in value.Map.Fields)
        {
            // A writeOnly field is a credential the server never returns.
            // Echoing one into JSON output would put it somewhere it was never
            // meant to be -- a log, a bug report, a saved fixture.
            if (field.WriteOnly) { continue; }
            writer.WritePropertyName(field.Name);
            JsonNode? wire = field.ToWire(value.ReadDeclared(field.Name));
            if (wire is null) { writer.WriteNullValue(); } else { wire.WriteTo(writer, options); }
        }

        foreach (string name in value.GetUndeclaredFieldNames())
        {
            writer.WritePropertyName(name);
            JsonNode? extra = value.FieldNode(name);
            if (extra is null) { writer.WriteNullValue(); } else { extra.WriteTo(writer, options); }
        }

        writer.WriteEndObject();
    }
}
