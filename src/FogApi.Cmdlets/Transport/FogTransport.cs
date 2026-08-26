namespace FogApi;

/// <summary>
/// The transport every FOG request goes through, and the one place to swap it.
/// </summary>
/// <remarks>
/// Public and supported rather than an internal test hook. A seam that is not
/// shipped cannot be used by anyone else's tests either, and the module's own
/// suite is not the only thing that needs to intercept FOG calls -- anyone
/// writing tests around a script that uses FogApi has the same problem.
/// </remarks>
public static class FogTransport
{
    private static readonly Lazy<IFogTransport> DefaultTransport =
        new(() => new FogHttpTransport(), isThreadSafe: true);

    private static IFogTransport? _override;

    /// <summary>The transport in effect.</summary>
    public static IFogTransport Current => _override ?? DefaultTransport.Value;

    /// <summary>True when something has replaced the real transport.</summary>
    public static bool IsOverridden => _override is not null;

    /// <summary>Replaces the transport. Null restores the real one.</summary>
    public static void Set(IFogTransport? transport) => _override = transport;

    /// <summary>Restores the real transport.</summary>
    public static void Reset() => _override = null;
}
