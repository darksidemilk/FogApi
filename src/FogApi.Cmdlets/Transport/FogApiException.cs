using System.Net;

namespace FogApi;

/// <summary>
/// A FOG API call that failed, carrying what the server actually said.
/// </summary>
/// <remarks>
/// <para>
/// FOG puts the real reason in the response BODY, not the status line. That is
/// the whole point of this type. Invoke-FogApi caught every failure from
/// Invoke-RestMethod and retried through Invoke-WebRequest, which cost a second
/// round trip and replaced a message like "Invalid hostname; must be 1-15 of
/// these characters" with a bare "Response status code does not indicate
/// success: 406". The retry looked like resilience and was actually losing the
/// only useful part of the answer.
/// </para>
/// </remarks>
public sealed class FogApiException : Exception
{
    /// <summary>HTTP status, when the failure was a response rather than a local one.</summary>
    public HttpStatusCode? StatusCode { get; }

    /// <summary>The request method, when there was one.</summary>
    public string? Method { get; }

    /// <summary>The request URI, when there was one.</summary>
    public Uri? RequestUri { get; }

    /// <summary>The raw response body, which is where FOG puts the reason.</summary>
    public string? ResponseBody { get; }

    /// <summary>A local failure with no request behind it.</summary>
    public FogApiException(string message) : base(message) { }

    /// <summary>A local failure with an inner cause.</summary>
    public FogApiException(string message, Exception inner) : base(message, inner) { }

    /// <summary>A failed response.</summary>
    public FogApiException(string method, Uri requestUri, HttpStatusCode status, string? body)
        : base(BuildMessage(method, requestUri, status, body))
    {
        Method = method;
        RequestUri = requestUri;
        StatusCode = status;
        ResponseBody = body;
    }

    private static string BuildMessage(string method, Uri uri, HttpStatusCode status, string? body)
    {
        string reason = ExtractReason(body);
        return string.IsNullOrWhiteSpace(reason)
            ? $"{method} {uri} failed with {(int)status} {status}."
            : $"{method} {uri} failed with {(int)status} {status}: {reason}";
    }

    /// <summary>
    /// Pulls FOG's own message out of an error body.
    /// </summary>
    /// <remarks>
    /// The documented shape is {"error": "..."}, and that is tried first. A body
    /// that is not that shape is surfaced verbatim rather than discarded --
    /// losing it is the exact defect this type exists to fix -- but trimmed,
    /// because an unhandled PHP failure can answer with a whole HTML page and
    /// that is not something to put in an exception message.
    /// </remarks>
    private static string ExtractReason(string? body)
    {
        if (string.IsNullOrWhiteSpace(body))
        {
            return string.Empty;
        }

        try
        {
            using System.Text.Json.JsonDocument doc = System.Text.Json.JsonDocument.Parse(body);
            if (doc.RootElement.ValueKind == System.Text.Json.JsonValueKind.Object &&
                doc.RootElement.TryGetProperty("error", out System.Text.Json.JsonElement error) &&
                error.ValueKind == System.Text.Json.JsonValueKind.String)
            {
                return error.GetString() ?? string.Empty;
            }
        }
        catch (System.Text.Json.JsonException)
        {
            // Not JSON. Fall through and surface it raw.
        }

        string trimmed = body.Trim();
        const int cap = 500;
        return trimmed.Length <= cap ? trimmed : trimmed[..cap] + "...";
    }
}
