using System.Net.Http.Headers;
using System.Text;

namespace FogApi;

/// <summary>
/// The real transport: the single place credentials, base URI and error mapping
/// live.
/// </summary>
public sealed class FogHttpTransport : IFogTransport, IDisposable
{
    private readonly HttpClient _http;
    private readonly Func<FogServerSettings> _settings;

    /// <summary>
    /// True when this transport was given a handler and so cannot reach the
    /// network.
    /// </summary>
    /// <remarks>
    /// The FOGAPI_FORBID_NETWORK guard keys off this. The variable means "no
    /// real egress", not "no requests" -- a transport holding an injected
    /// handler is already incapable of egress, and refusing it would block the
    /// very tests the guard exists to protect.
    /// </remarks>
    public bool IsStubbed { get; }

    /// <summary>
    /// Environment variable that makes a real request throw.
    /// </summary>
    /// <remarks>
    /// Set by every mocked test. A suite whose transport mock stopped
    /// intercepting would otherwise go green while talking to a real server;
    /// this turns that into a loud failure on every machine, forever. It is the
    /// backstop for a failure mode that is silent by nature.
    /// </remarks>
    public const string ForbidNetworkVariable = "FOGAPI_FORBID_NETWORK";

    /// <summary>
    /// Creates a transport.
    /// </summary>
    /// <param name="handler">
    /// Message handler. Injectable because this is where a test intercepts:
    /// a stub handler here replaces what <c>Mock Invoke-RestMethod</c> used to
    /// do, and is the only thing that can, once transport is compiled.
    /// </param>
    /// <param name="settings">
    /// How to obtain settings. Defaults to reading the per-user file on every
    /// call, which is what Invoke-FogApi has always done.
    /// </param>
    public FogHttpTransport(HttpMessageHandler? handler = null, Func<FogServerSettings>? settings = null)
    {
        IsStubbed = handler is not null;
        _http = handler is null ? new HttpClient() : new HttpClient(handler, disposeHandler: true);
        _http.Timeout = TimeSpan.FromSeconds(100);
        _settings = settings ?? (() => FogServerSettings.Load());
    }

    /// <inheritdoc/>
    public FogResponse Send(FogRequest request)
    {
        if (!IsStubbed && Environment.GetEnvironmentVariable(ForbidNetworkVariable) == "1")
        {
            throw new FogApiException(
                $"FogApi tried to make a real request ({request.Method} {request.UriPath}) while " +
                $"{ForbidNetworkVariable} is set. A transport mock was expected to intercept it. " +
                "Either the test forgot Set-FogTransport, or a code path bypassed FogTransport.Current.");
        }

        FogServerSettings settings = _settings();
        Uri uri = new(settings.BaseUri(), request.UriPath.TrimStart('/'));

        using HttpRequestMessage message = new(new HttpMethod(request.Method), uri);
        ApplyCredentials(message, settings);

        if (!string.IsNullOrEmpty(request.JsonData))
        {
            message.Content = new StringContent(request.JsonData, Encoding.UTF8, "application/json");
        }

        HttpResponseMessage response;
        try
        {
            response = _http.Send(message);
        }
        catch (HttpRequestException ex)
        {
            throw new FogApiException($"{request.Method} {uri} could not be sent: {ex.Message}", ex);
        }
        catch (TaskCanceledException ex)
        {
            throw new FogApiException($"{request.Method} {uri} timed out after {_http.Timeout}.", ex);
        }

        using (response)
        {
            string body = response.Content.ReadAsStringAsync().GetAwaiter().GetResult();

            if (!response.IsSuccessStatusCode)
            {
                // The body, not the status line. See FogApiException.
                throw new FogApiException(request.Method, uri, response.StatusCode, body);
            }

            return new FogResponse((int)response.StatusCode, body);
        }
    }

    private static void ApplyCredentials(HttpRequestMessage message, FogServerSettings settings)
    {
        if (settings.UsesBearer)
        {
            // Sufficient on its own; ADR 0027 is explicit that no fog-api-token
            // is needed beside it. Sending both would be harmless but would
            // muddy which credential an audit entry actually accepted.
            message.Headers.Authorization = new AuthenticationHeaderValue("Bearer", settings.FogBearerToken);
            return;
        }

        // TryAddWithoutValidation, because these are opaque base64 blobs and the
        // typed header parser has opinions about what belongs in a header value.
        //
        // Sent VERBATIM. The router does base64_decode() on the way in, which
        // reads as though a client should encode -- it must not. The value the
        // UI shows is already encoded, and encoding it again 401s every call.
        // Worse, it is hard to spot: hex is itself valid base64, so a
        // double-encoded token still looks like a token.
        message.Headers.TryAddWithoutValidation("fog-api-token", settings.FogApiToken);
        message.Headers.TryAddWithoutValidation("fog-user-token", settings.FogUserToken);
    }

    /// <inheritdoc/>
    public void Dispose() => _http.Dispose();
}
