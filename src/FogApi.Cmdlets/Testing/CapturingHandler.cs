using System.Net;
using System.Text;

namespace FogApi.Testing;

/// <summary>
/// An <see cref="HttpMessageHandler"/> that records what was sent and answers
/// with a canned response.
/// </summary>
/// <remarks>
/// <para>
/// Shipped in the module rather than living in the test project, for the same
/// reason <c>Set-FogTransport</c> is public: the transport contract is not
/// only FogApi's to test. It is also the only way to assert on the parts of a
/// request that never reach <see cref="IFogTransport"/> -- the URI actually
/// built and the headers actually attached -- because that seam is above them.
/// </para>
/// <para>
/// Those assertions used to belong to <c>Tests/Invoke-FogApi.Tests.ps1</c>,
/// which mocked <c>Invoke-RestMethod</c>. That seam disappears with the move to
/// compiled transport, and this is what replaces it.
/// </para>
/// </remarks>
public sealed class CapturingHandler : HttpMessageHandler
{
    private readonly string _body;
    private readonly HttpStatusCode _status;

    /// <summary>The URI of the last request.</summary>
    public Uri? LastRequestUri { get; private set; }

    /// <summary>The method of the last request.</summary>
    public string? LastMethod { get; private set; }

    /// <summary>The body of the last request, if it had one.</summary>
    public string? LastBody { get; private set; }

    /// <summary>Headers of the last request, flattened to one value each.</summary>
    public Dictionary<string, string> LastHeaders { get; } = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>How many requests reached this handler.</summary>
    public int CallCount { get; private set; }

    /// <summary>Creates a handler that answers every request the same way.</summary>
    public CapturingHandler(string body = "{}", HttpStatusCode status = HttpStatusCode.OK)
    {
        _body = body;
        _status = status;
    }

    /// <inheritdoc/>
    protected override HttpResponseMessage Send(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        Capture(request);
        return new HttpResponseMessage(_status)
        {
            Content = new StringContent(_body, Encoding.UTF8, "application/json"),
        };
    }

    /// <inheritdoc/>
    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        => Task.FromResult(Send(request, cancellationToken));

    private void Capture(HttpRequestMessage request)
    {
        CallCount++;
        LastRequestUri = request.RequestUri;
        LastMethod = request.Method.Method;

        LastHeaders.Clear();
        foreach (KeyValuePair<string, IEnumerable<string>> header in request.Headers)
        {
            LastHeaders[header.Key] = string.Join(",", header.Value);
        }

        LastBody = request.Content?.ReadAsStringAsync().GetAwaiter().GetResult();
    }
}
