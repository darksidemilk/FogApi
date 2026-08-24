using System.Management.Automation;

namespace FogApi.Cmdlets;

/// <summary>
/// Replaces the transport every FOG call goes through, for the life of the
/// session.
/// </summary>
/// <remarks>
/// <para>
/// This is how a test intercepts FOG calls now. <c>Mock -ModuleName FogApi
/// Invoke-FogApi</c> cannot: Pester injects a mock into a module's session
/// state, and a compiled cmdlet does not resolve its dependencies through
/// session state. That mock installs successfully and intercepts nothing --
/// it fails open, so a run believed to be mocked would talk to a real server
/// and mutate it.
/// </para>
/// <para>Set FOGAPI_FORBID_NETWORK=1 alongside this, so a call that slips past
/// the mock throws instead of going out.</para>
/// </remarks>
[Cmdlet(VerbsCommon.Set, "FogTransport")]
[OutputType(typeof(void))]
public sealed class SetFogTransportCommand : PSCmdlet
{
    /// <summary>
    /// Receives <c>$uriPath, $method, $jsonData</c> and returns the response
    /// body -- a string is used as-is, anything else is serialised.
    /// </summary>
    [Parameter(Mandatory = true, Position = 0)]
    [ValidateNotNull]
    public ScriptBlock ScriptBlock { get; set; } = null!;

    /// <summary>Return the transport object rather than nothing.</summary>
    [Parameter]
    public SwitchParameter PassThru { get; set; }

    /// <inheritdoc/>
    protected override void EndProcessing()
    {
        ScriptBlockTransport transport = new(ScriptBlock);
        FogTransport.Set(transport);
        WriteVerbose("FogApi transport replaced; real HTTP requests will not be made.");

        if (PassThru)
        {
            // Handing it back is what lets a test assert CallCount, which is
            // the check that catches a mock that stopped intercepting.
            WriteObject(transport);
        }
    }
}

/// <summary>Restores the real HTTP transport.</summary>
[Cmdlet(VerbsCommon.Reset, "FogTransport")]
[OutputType(typeof(void))]
public sealed class ResetFogTransportCommand : PSCmdlet
{
    /// <inheritdoc/>
    protected override void EndProcessing()
    {
        FogTransport.Reset();
        WriteVerbose("FogApi transport restored to real HTTP.");
    }
}
