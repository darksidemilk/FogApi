using System.Management.Automation;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace FogApi;

/// <summary>JSON conventions shared by everything that talks to FOG.</summary>
public static class FogJson
{
    /// <summary>Options for everything sent to, or read from, the server.</summary>
    public static readonly JsonSerializerOptions Wire = new()
    {
        // FOG hands back "42" for integer columns as often as 42, because the
        // values come out of MySQL as strings. Refusing those would fail on
        // real responses.
        NumberHandling = System.Text.Json.Serialization.JsonNumberHandling.AllowReadingFromString,
        PropertyNameCaseInsensitive = true,
        // FOG stores values that are full of characters the default encoder
        // escapes -- an AD OU is all backslashes and equals signs. Escaping
        // them is valid JSON and unreadable, and it makes a payload diff in a
        // bug report impossible to follow.
        Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping,
        WriteIndented = false,
    };

    /// <summary>
    /// Converts a parsed JSON node into the objects PowerShell expects.
    /// </summary>
    /// <remarks>
    /// Deliberately the same shape ConvertFrom-Json produces -- PSCustomObject
    /// for an object, an array for an array, primitives for the rest -- because
    /// every existing script that consumes Invoke-FogApi was written against
    /// that. This is the escape hatch; changing what it returns would break the
    /// callers least able to absorb it.
    /// </remarks>
    public static object? ToPowerShell(JsonNode? node)
    {
        switch (node)
        {
            case null:
                return null;

            case JsonArray array:
                return array.Select(ToPowerShell).ToArray();

            case JsonObject obj:
            {
                PSObject result = new();
                foreach (KeyValuePair<string, JsonNode?> pair in obj)
                {
                    result.Properties.Add(new PSNoteProperty(pair.Key, ToPowerShell(pair.Value)));
                }
                return result;
            }

            case JsonValue value:
            {
                if (value.TryGetValue(out bool b)) { return b; }
                // long before double, so an id does not come back as 1.234E+4.
                if (value.TryGetValue(out long l)) { return l; }
                if (value.TryGetValue(out double d)) { return d; }
                if (value.TryGetValue(out string? s)) { return s; }
                return value.ToJsonString();
            }

            default:
                return node.ToJsonString();
        }
    }
}
