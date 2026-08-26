using System.Management.Automation;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace FogApi.Cmdlets;

/// <summary>
/// The transport layer of the FOG API, and the escape hatch for anything the
/// typed cmdlets do not cover.
/// </summary>
/// <remarks>
/// <para>
/// Hand-written, not generated: transport is not an API operation, it is the
/// thing every operation goes through. It stays public because the tier 5 fixed
/// routes have no L1 representation, because a plugin's classes never appear in
/// a checked-in snapshot and are only reachable generically, and because a
/// great deal of existing script calls it by name.
/// </para>
/// </remarks>
[Cmdlet(VerbsLifecycle.Invoke, "FogApi")]
[OutputType(typeof(PSObject))]
public sealed class InvokeFogApiCommand : PSCmdlet
{
    /// <summary>Path relative to the webroot, e.g. <c>host/1234</c>.</summary>
    [Parameter(Mandatory = true, Position = 0, ValueFromPipelineByPropertyName = true)]
    [ValidateNotNullOrEmpty]
    public string uriPath { get; set; } = string.Empty;

    /// <summary>HTTP method.</summary>
    /// <remarks>
    /// A ValidateSet where the old parameter was a bare string. FOG serves
    /// these five and nothing else, and a typo used to become a request the
    /// server rejected for a reason that never named the method.
    /// </remarks>
    [Parameter(Position = 1, ValueFromPipelineByPropertyName = true)]
    [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH", IgnoreCase = true)]
    public string Method { get; set; } = "GET";

    /// <summary>Request body, already serialised as JSON.</summary>
    [Parameter(Position = 2, ValueFromPipelineByPropertyName = true)]
    public string? jsonData { get; set; }

    /// <summary>Return the raw response body instead of parsing it.</summary>
    [Parameter]
    public SwitchParameter Raw { get; set; }

    /// <inheritdoc/>
    protected override void ProcessRecord()
    {
        string method = Method.ToUpperInvariant();

        if (method == "GET" && !string.IsNullOrEmpty(jsonData))
        {
            WriteWarning(
                "A body was supplied with a GET. If this is meant to change something it probably wants to be a POST.");
        }

        WriteVerbose($"{method} {uriPath}");

        FogResponse response = FogTransport.Current.Send(new FogRequest(uriPath, method, jsonData));

        // An empty body is a success, not a failure to parse. FOG answers task
        // and cancel with two bytes, and every one of those would otherwise
        // look like a broken response.
        if (response.IsEmpty)
        {
            WriteVerbose("empty response body");
            return;
        }

        if (Raw)
        {
            WriteObject(response.Body);
            return;
        }

        WriteObject(Parse(response.Body), enumerateCollection: false);
    }

    /// <summary>
    /// Turns a JSON body into PowerShell objects.
    /// </summary>
    /// <remarks>
    /// A body that is not JSON is returned as the string it is, rather than
    /// throwing. Some FOG routes answer with plain text, and a caller reaching
    /// for the escape hatch is the caller least able to afford this being
    /// opinionated.
    /// </remarks>
    private object? Parse(string body)
    {
        try
        {
            JsonNode? node = JsonNode.Parse(body);
            // A body of literal `null` parses to null, which is a real answer
            // and not the same as an unparseable one.
            return node is null ? null : FogJson.ToPowerShell(node);
        }
        catch (JsonException)
        {
            WriteVerbose("response was not JSON; returning it as text");
            return body;
        }
    }
}
