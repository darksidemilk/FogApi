using System.Globalization;
using System.Management.Automation;
using System.Text.Json.Nodes;

namespace FogApi.Models;

/// <summary>
/// How a field is spelled on the wire. One value per <c>wireType</c> in
/// spec/fog-api-spec.json.
/// </summary>
public enum FogWire
{
    /// <summary>A string.</summary>
    String,

    /// <summary>A whole number.</summary>
    Int,

    /// <summary>A fractional number.</summary>
    Number,

    /// <summary>A real JSON boolean. FOG uses none today.</summary>
    Bool,

    /// <summary>
    /// A boolean the caller thinks in, transmitted as the STRING "0" or "1".
    /// </summary>
    /// <remarks>
    /// Distinct from <see cref="Bool"/> on purpose. FOG spells every boolean
    /// column <c>enum('0','1')</c> -- 25 of them -- and a JSON <c>true</c> is a
    /// different request.
    /// </remarks>
    Bool01,

    /// <summary>An ISO timestamp.</summary>
    DateTime,

    /// <summary>A date with no time.</summary>
    Date,
}

/// <summary>One field of an entity, as the spec describes it.</summary>
/// <param name="Name">The name on the wire and in PowerShell.</param>
/// <param name="Column">The MySQL column behind it, for diagnostics.</param>
/// <param name="Wire">How the value is spelled.</param>
/// <param name="MaxLength">varchar length, when the column has one.</param>
/// <param name="ReadOnly">Returned but never accepted.</param>
/// <param name="WriteOnly">Accepted but never returned. Credentials.</param>
public sealed record FogField(
    string Name,
    string Column,
    FogWire Wire,
    int? MaxLength = null,
    bool ReadOnly = false,
    bool WriteOnly = false)
{
    /// <summary>Converts a caller's value into what FOG expects.</summary>
    public JsonNode? ToWire(object? value)
    {
        if (value is null) { return null; }
        if (value is PSObject pso) { value = pso.BaseObject; }

        return Wire switch
        {
            FogWire.Bool01 => JsonValue.Create(ToZeroOne(value)),
            FogWire.Bool => JsonValue.Create(Convert.ToBoolean(value, CultureInfo.InvariantCulture)),
            FogWire.Int => JsonValue.Create(Convert.ToInt64(value, CultureInfo.InvariantCulture)),
            FogWire.Number => JsonValue.Create(Convert.ToDouble(value, CultureInfo.InvariantCulture)),
            FogWire.DateTime => JsonValue.Create(ToFogDateTime(value)),
            FogWire.Date => JsonValue.Create(ToFogDate(value)),
            _ => JsonValue.Create(value.ToString()),
        };
    }

    /// <summary>
    /// A 0/1 column's value, as the string FOG stores.
    /// </summary>
    /// <remarks>
    /// An integer that is not 0 or 1 THROWS rather than being truthy-ed. That
    /// rule is the generalisation of a real bug: deploySnapins is
    /// <c>oneOf [string, integer, boolean]</c> and its values are -1 (every
    /// snapin), 0 (none), or a snapin id. Reading it as a boolean turned -1
    /// into true and put "1" on the wire -- a different snapin task, queued
    /// silently. Never guess what a number meant; make the caller say.
    /// </remarks>
    private string ToZeroOne(object value) => value switch
    {
        bool b => b ? "1" : "0",
        SwitchParameter sw => sw.IsPresent ? "1" : "0",
        string s when s is "0" or "1" => s,
        string s when bool.TryParse(s, out bool parsed) => parsed ? "1" : "0",
        string s => throw new FogApiException(
            $"'{s}' is not a value for '{Name}', which is a 0/1 column. Use $true, $false, '0' or '1'."),
        _ when IsInteger(value) => Convert.ToInt64(value, CultureInfo.InvariantCulture) switch
        {
            0 => "0",
            1 => "1",
            var other => throw new FogApiException(
                $"{other} is not a value for '{Name}', which is a 0/1 column. " +
                "Pass $true or $false rather than a number, so there is no doubt which was meant."),
        },
        _ => throw new FogApiException($"cannot send a {value.GetType().Name} to '{Name}', which is a 0/1 column."),
    };

    private static bool IsInteger(object v) =>
        v is byte or sbyte or short or ushort or int or uint or long or ulong;

    private static string ToFogDateTime(object value) =>
        value is DateTime dt
            ? dt.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture)
            : value.ToString() ?? string.Empty;

    private static string ToFogDate(object value) =>
        value is DateTime dt
            ? dt.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
            : value.ToString() ?? string.Empty;

    /// <summary>
    /// Reads a datetime FOG sent, or null when it did not really send one.
    /// </summary>
    /// <remarks>
    /// MySQL answers an unset datetime column with 0000-00-00 00:00:00. That is
    /// not a date, it is the absence of one, and DateTime.Parse throws on it.
    /// Every consumer of a dateTime field has to go through here.
    /// </remarks>
    public static DateTime? FromFogDateTime(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) { return null; }
        if (value.StartsWith("0000-00-00", StringComparison.Ordinal)) { return null; }
        return DateTime.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out DateTime parsed)
            ? parsed
            : null;
    }
}

/// <summary>Every field of one entity, looked up by name.</summary>
public sealed class FogFieldMap
{
    private readonly Dictionary<string, FogField> _byName;

    /// <summary>All fields, in spec order.</summary>
    public IReadOnlyList<FogField> Fields { get; }

    /// <summary>Creates a map.</summary>
    public FogFieldMap(params FogField[] fields)
    {
        Fields = fields;
        _byName = fields.ToDictionary(f => f.Name, StringComparer.OrdinalIgnoreCase);
    }

    /// <summary>The field with this name, or null.</summary>
    public FogField? this[string name] =>
        _byName.TryGetValue(name, out FogField? field) ? field : null;

    /// <summary>True when the entity declares this field.</summary>
    public bool Declares(string name) => _byName.ContainsKey(name);
}
