using System.Text.Json.Nodes;

namespace FogApi;

/// <summary>
/// One page of a FOG list response.
/// </summary>
/// <remarks>
/// FOG 1.6 wraps a list in <c>{draw, recordsTotal, recordsFiltered, truncated,
/// data[], recordsReturned, firstUrl, prevUrl, nextUrl, lastUrl}</c>. FOG 1.5
/// has none of that and answers <c>{count, hosts[]}</c> -- the rows under a key
/// named for the class.
/// </remarks>
public sealed class FogEnvelope
{
    /// <summary>The rows in this page.</summary>
    public IReadOnlyList<JsonNode?> Rows { get; init; } = Array.Empty<JsonNode?>();

    /// <summary>The next page, or null when this is the last.</summary>
    public string? NextUrl { get; init; }

    /// <summary>True when the response carried a 1.6 paging envelope.</summary>
    /// <remarks>
    /// Structural, not a version probe. The alternative is asking the server
    /// what version it is before every list, and 1.5 simply ignores the paging
    /// query string, so the shape of the first answer already says everything
    /// the pager needs.
    /// </remarks>
    public bool ServerPaged { get; init; }

    /// <summary>Rows matching the filter, within what the caller may see.</summary>
    public long? RecordsFiltered { get; init; }

    /// <summary>Total rows the caller may see, unfiltered.</summary>
    public long? RecordsTotal { get; init; }

    /// <summary>Reads one response body.</summary>
    public static FogEnvelope Parse(FogResponse response)
    {
        if (response.IsEmpty) { return new FogEnvelope(); }

        JsonNode? root = JsonNode.Parse(response.Body);
        if (root is JsonArray bare)
        {
            // names and ids answer with a bare array and no envelope at all.
            return new FogEnvelope { Rows = bare.ToArray() };
        }
        if (root is not JsonObject obj) { return new FogEnvelope(); }

        bool hasReturned = obj.ContainsKey("recordsReturned");
        bool hasNext = obj.ContainsKey("nextUrl");

        JsonNode? rows = obj.TryGetPropertyValue("data", out JsonNode? data) ? data : null;
        if (rows is null)
        {
            // FOG 1.5: the rows sit under a key named for the class, alongside
            // count. Take the first array property rather than guessing the
            // pluralisation -- Add-FogResultData has always done the same, and
            // for the same reason.
            foreach (KeyValuePair<string, JsonNode?> pair in obj)
            {
                if (pair.Value is JsonArray) { rows = pair.Value; break; }
            }
        }

        return new FogEnvelope
        {
            Rows = rows is JsonArray array ? array.ToArray() : Array.Empty<JsonNode?>(),
            // A present-but-null nextUrl still means 1.6. Only its ABSENCE
            // means 1.5, which is why ServerPaged tests for the key and
            // NextUrl tests for the value.
            NextUrl = hasNext ? obj["nextUrl"]?.GetValue<string?>() : null,
            ServerPaged = hasReturned || hasNext,
            RecordsFiltered = ReadLong(obj, "recordsFiltered"),
            RecordsTotal = ReadLong(obj, "recordsTotal"),
        };
    }

    private static long? ReadLong(JsonObject obj, string key)
    {
        if (!obj.TryGetPropertyValue(key, out JsonNode? node) || node is not JsonValue value) { return null; }
        if (value.TryGetValue(out long l)) { return l; }
        if (value.TryGetValue(out string? s) && long.TryParse(s, out long parsed)) { return parsed; }
        return null;
    }
}
