namespace FogApi;

/// <summary>One FOG API request.</summary>
/// <param name="UriPath">Path relative to the webroot, e.g. <c>host/1234</c>.</param>
/// <param name="Method">HTTP method.</param>
/// <param name="JsonData">Request body, already serialised, or null.</param>
public sealed record FogRequest(string UriPath, string Method = "GET", string? JsonData = null);

/// <summary>One FOG API response.</summary>
/// <param name="StatusCode">HTTP status.</param>
/// <param name="Body">
/// Raw body. Empty is a legitimate success: FOG answers some writes -- task and
/// cancel among them -- with a two byte body, and treating that as a parse
/// failure would break every one of them.
/// </param>
public sealed record FogResponse(int StatusCode, string Body)
{
    /// <summary>True when the body carries nothing to parse.</summary>
    public bool IsEmpty => string.IsNullOrWhiteSpace(Body);
}

/// <summary>
/// The seam every FOG request passes through.
/// </summary>
/// <remarks>
/// <para>
/// This exists as an interface for one reason above all others: testability,
/// and specifically because the old way of testing stops working here. The
/// entire mocked suite intercepted at <c>Mock -ModuleName FogApi
/// Invoke-FogApi</c>. Pester injects a mock into a module's session state, and
/// a compiled cmdlet does not resolve its dependencies through session state --
/// it makes a direct method call. So that mock installs successfully and
/// intercepts nothing.
/// </para>
/// <para>
/// It fails OPEN, which is the dangerous direction: a run everyone believes is
/// mocked would make real calls against whatever server the local settings file
/// names, and mutate it. Hence a swappable transport that ships as a supported
/// feature rather than a test hook, and hence the FOGAPI_FORBID_NETWORK guard
/// in <see cref="FogHttpTransport"/>.
/// </para>
/// </remarks>
public interface IFogTransport
{
    /// <summary>Sends a request and returns the response.</summary>
    FogResponse Send(FogRequest request);
}
