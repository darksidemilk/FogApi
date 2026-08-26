using System.Text.Json;
using System.Text.Json.Serialization;

namespace FogApi;

/// <summary>
/// The per-user settings file: which server, and the credentials for it.
/// </summary>
/// <remarks>
/// <para>
/// This type only READS. Creating the file, bootstrapping it from the template,
/// tightening its permissions, migrating the old posix path and opening an
/// editor when a value is still a placeholder all stay in
/// Get-FogServerSettings / Set-FogServerSettings, which are registered
/// hand-written for exactly that reason: they are an interactive config UX, not
/// transport. Splitting it this way means the compiled half has no opinion
/// about how the file came to exist.
/// </para>
/// <para>
/// Read per call rather than cached, matching what Invoke-FogApi has always
/// done. Caching is a real improvement and a separate change: it would need an
/// invalidation story for Set-FogServerSettings and Enable-FogApiHTTPS, both of
/// which rewrite the file underneath a live session.
/// </para>
/// </remarks>
public sealed class FogServerSettings
{
    /// <summary>Server-wide API token, from FOG Settings &gt; API System.</summary>
    [JsonPropertyName("fogApiToken")]
    public string FogApiToken { get; set; } = string.Empty;

    /// <summary>Per-user API token, from the API tab of an API-enabled user.</summary>
    [JsonPropertyName("fogUserToken")]
    public string FogUserToken { get; set; } = string.Empty;

    /// <summary>Hostname, or a full scheme-qualified base URL.</summary>
    [JsonPropertyName("fogServer")]
    public string FogServer { get; set; } = string.Empty;

    /// <summary>
    /// A <c>fog_</c> prefixed token sent as <c>Authorization: Bearer</c>.
    /// </summary>
    /// <remarks>
    /// Optional, and additive. ADR 0027 made a Bearer credential a row in
    /// apiTokens rather than a second spelling of users.uAPIToken: hashed at
    /// rest, shown once, individually revocable. It is sufficient on its own,
    /// so when this is set the two header tokens are not sent.
    /// <para>
    /// users.uAPIToken is untouched upstream and keeps working as
    /// fog-user-token, so a settings file that predates this field behaves
    /// exactly as it did.
    /// </para>
    /// </remarks>
    [JsonPropertyName("fogBearerToken")]
    public string? FogBearerToken { get; set; }

    private static readonly JsonSerializerOptions ReadOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        ReadCommentHandling = JsonCommentHandling.Skip,
        AllowTrailingCommas = true,
    };

    /// <summary>
    /// Where the settings file lives for the current user, matching
    /// Get-FogServerSettingsFile exactly.
    /// </summary>
    public static string ResolvePath()
    {
        if (OperatingSystem.IsWindows())
        {
            string appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            return Path.Combine(appData, "FogApi", "api-settings.json");
        }

        string home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        return Path.Combine(home, ".FogApi", "api-settings.json");
    }

    /// <summary>Reads and validates the settings file.</summary>
    /// <exception cref="FogApiException">
    /// The file is missing, unreadable, malformed, or still holds the template
    /// placeholders.
    /// </exception>
    public static FogServerSettings Load(string? path = null)
    {
        path ??= ResolvePath();

        if (!File.Exists(path))
        {
            throw new FogApiException(
                $"No FogApi settings file at {path}. Run Set-FogServerSettings to create one.");
        }

        FogServerSettings? settings;
        try
        {
            settings = JsonSerializer.Deserialize<FogServerSettings>(File.ReadAllText(path), ReadOptions);
        }
        catch (JsonException ex)
        {
            throw new FogApiException($"The FogApi settings file at {path} is not valid JSON: {ex.Message}", ex);
        }

        if (settings is null)
        {
            throw new FogApiException($"The FogApi settings file at {path} is empty.");
        }

        settings.Validate(path);
        return settings;
    }

    private void Validate(string path)
    {
        // The template ships prose in every value, so a file that has been
        // created but never filled in parses fine and then 401s with nothing
        // useful to say. The placeholders are sentences; a real token is not.
        // Testing for whitespace catches them without pinning the exact wording.
        foreach ((string name, string? value) in new[]
                 {
                     (nameof(FogServer), FogServer),
                     (nameof(FogApiToken), FogApiToken),
                     (nameof(FogUserToken), FogUserToken),
                 })
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                throw new FogApiException(
                    $"{name} is not set in {path}. Run Set-FogServerSettings -interactive.");
            }

            if (value.Contains(' '))
            {
                throw new FogApiException(
                    $"{name} in {path} still holds the template placeholder text. " +
                    "Run Set-FogServerSettings -interactive to fill it in.");
            }
        }
    }

    /// <summary>
    /// The base URI every request is built against, ending in a trailing slash.
    /// </summary>
    /// <remarks>
    /// Built with <see cref="Uri"/> rather than by string concatenation.
    /// Invoke-FogApi normalised with .Replace('//','/') and then put the scheme
    /// back, which also collapsed any legitimate double slash further along the
    /// path.
    /// </remarks>
    public Uri BaseUri()
    {
        string server = FogServer.Trim();

        // Validate() catches a placeholder on the way in, but only Load() calls
        // it. Checking again here means a settings object built some other way
        // still fails with something a caller can act on, rather than with
        // "Invalid URI: The hostname could not be parsed" from a Uri
        // constructor that was handed a sentence.
        if (string.IsNullOrWhiteSpace(server))
        {
            throw new FogApiException(
                "No fogServer is configured. Run Set-FogServerSettings -interactive.");
        }

        if (!server.StartsWith("http://", StringComparison.OrdinalIgnoreCase) &&
            !server.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            server = "http://" + server;
        }

        if (!Uri.TryCreate(server.TrimEnd('/') + "/fog/", UriKind.Absolute, out Uri? uri))
        {
            throw new FogApiException(
                $"fogServer is not a usable server address: '{FogServer}'. " +
                "It wants a hostname, an address, or a full URL. " +
                "Run Set-FogServerSettings -interactive.");
        }

        return uri;
    }

    /// <summary>True when a Bearer credential is configured.</summary>
    public bool UsesBearer => !string.IsNullOrWhiteSpace(FogBearerToken);
}
