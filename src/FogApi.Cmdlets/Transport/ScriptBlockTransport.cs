using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Text.Json;

namespace FogApi;

/// <summary>
/// A transport backed by a PowerShell scriptblock. This is what a test uses.
/// </summary>
/// <remarks>
/// <para>
/// Replaces <c>Mock -ModuleName FogApi Invoke-FogApi</c>, which cannot work
/// once transport is compiled. The scriptblock receives the same three values
/// Invoke-FogApi took, so an existing mock body ports almost unchanged:
/// </para>
/// <code>
/// Set-FogTransport -ScriptBlock {
///     param($uriPath, $method, $jsonData)
///     Get-FogMockResponse -uriPath $uriPath -Method $method -jsonData $jsonData
/// }
/// </code>
/// <para>
/// A scriptblock returning a string is treated as the raw body. Anything else
/// is serialised, so a mock can hand back a hashtable or a PSCustomObject and
/// not think about JSON.
/// </para>
/// </remarks>
public sealed class ScriptBlockTransport : IFogTransport
{
    private readonly ScriptBlock _script;

    /// <summary>How many times this transport has been reached.</summary>
    /// <remarks>
    /// A mocked suite that stopped intercepting is worse than no suite: it goes
    /// green while talking to something real. Asserting this is non-zero after
    /// a test is what catches a code path that bypassed FogTransport.Current.
    /// </remarks>
    public int CallCount { get; private set; }

    /// <summary>Creates a transport that calls the given scriptblock.</summary>
    public ScriptBlockTransport(ScriptBlock script)
        => _script = script ?? throw new ArgumentNullException(nameof(script));

    private static readonly JsonSerializerOptions SerializeOptions = new()
    {
        WriteIndented = false,
    };

    /// <inheritdoc/>
    public FogResponse Send(FogRequest request)
    {
        CallCount++;

        Collection<PSObject> results = _script.Invoke(request.UriPath, request.Method, request.JsonData);

        object? value = results.Count switch
        {
            0 => null,
            1 => results[0]?.BaseObject,
            _ => results.Select(r => r?.BaseObject).ToArray(),
        };

        return new FogResponse(200, Render(value));
    }

    private static string Render(object? value) => value switch
    {
        null => string.Empty,
        string s => s,
        // A mock that hands back a Hashtable or a PSCustomObject should not
        // have to serialise it itself. PSObject is unwrapped first because
        // serialising one directly emits its adapter members, not its data.
        PSObject pso => Render(pso.BaseObject),
        _ => JsonSerializer.Serialize(value, SerializeOptions),
    };
}
