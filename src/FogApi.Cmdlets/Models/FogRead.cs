using System.Globalization;
using System.Text.Json.Nodes;

namespace FogApi.Models;

/// <summary>
/// Reads a value FOG sent into the type the model declares.
/// </summary>
/// <remarks>
/// Every generated <c>SetDeclared</c> goes through here, so the tolerances live
/// in one place rather than in 431 switch arms.
/// <para>
/// The tolerance that matters: values come out of MySQL as strings, so an
/// integer column arrives as <c>"42"</c> about as often as <c>42</c>, and a
/// reader that accepted only one of those would fail on real responses.
/// </para>
/// </remarks>
public static class FogRead
{
    /// <summary>A string, or null.</summary>
    public static string? String(JsonNode? node) => node switch
    {
        null => null,
        JsonValue v when v.TryGetValue(out string? s) => s,
        _ => node.ToString(),
    };

    /// <summary>A whole number, tolerating the string form.</summary>
    public static long? Int(JsonNode? node)
    {
        if (node is not JsonValue value) { return null; }
        if (value.TryGetValue(out long l)) { return l; }
        if (value.TryGetValue(out string? s))
        {
            // An empty string is FOG's way of saying nothing, not zero. Reading
            // it as 0 would make an unset foreign key look like a real id.
            if (string.IsNullOrWhiteSpace(s)) { return null; }
            return long.TryParse(s, NumberStyles.Integer, CultureInfo.InvariantCulture, out long parsed)
                ? parsed
                : null;
        }
        return null;
    }

    /// <summary>A fractional number, tolerating the string form.</summary>
    public static double? Number(JsonNode? node)
    {
        if (node is not JsonValue value) { return null; }
        if (value.TryGetValue(out double d)) { return d; }
        if (value.TryGetValue(out string? s) && !string.IsNullOrWhiteSpace(s))
        {
            return double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out double parsed)
                ? parsed
                : null;
        }
        return null;
    }

    /// <summary>
    /// A 0/1 column, as the boolean the caller thinks in.
    /// </summary>
    /// <remarks>
    /// Reading is more forgiving than writing on purpose. Writing throws on an
    /// ambiguous number, because the caller can be asked what they meant;
    /// reading cannot ask anyone, and refusing a row because one column held
    /// something unexpected would make the whole response unusable.
    /// </remarks>
    public static bool? Bool01(JsonNode? node)
    {
        if (node is not JsonValue value) { return null; }
        if (value.TryGetValue(out bool b)) { return b; }
        if (value.TryGetValue(out long l)) { return l != 0; }
        if (value.TryGetValue(out string? s))
        {
            if (string.IsNullOrWhiteSpace(s)) { return null; }
            if (s is "0") { return false; }
            if (s is "1") { return true; }
            return bool.TryParse(s, out bool parsed) ? parsed : null;
        }
        return null;
    }

    /// <summary>A timestamp, with MySQL's zero date read as null.</summary>
    public static DateTime? DateTime(JsonNode? node) => FogField.FromFogDateTime(String(node));
}
