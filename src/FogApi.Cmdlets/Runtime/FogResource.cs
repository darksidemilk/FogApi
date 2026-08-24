using System.Text.Json;
using System.Text.Json.Nodes;
using FogApi.Models;

namespace FogApi;

/// <summary>
/// The generic CRUD layer: what L1 means, now that it is a type rather than
/// five cmdlets.
/// </summary>
/// <remarks>
/// <para>
/// One closed instance per route class. It knows the route SHAPES, not the
/// classes -- which is the same division the spec draws, where a class picks a
/// tier and a tier picks a set of shapes.
/// </para>
/// <para>
/// The five L1 cmdlets remain the PowerShell face of this. They are how a
/// caller reaches a class this build has no typed cmdlet for, which is the only
/// answer to a plugin's classes: a plugin's routes never appear in a
/// checked-in snapshot, so nothing generated can cover them.
/// </para>
/// <para>
/// Synchronous on purpose. A PowerShell cmdlet is synchronous, ProcessRecord
/// cannot be async, and there is no SynchronizationContext in a runspace to
/// deadlock against -- so async here would buy nothing and cost a
/// GetAwaiter().GetResult() at every call site.
/// </para>
/// </remarks>
/// <typeparam name="TEntity">The entity this resource returns.</typeparam>
public sealed class FogResource<TEntity> where TEntity : FogEntity, new()
{
    private readonly IFogTransport _transport;
    private readonly string _class;

    /// <summary>Creates a resource for one route class.</summary>
    public FogResource(IFogTransport transport, string fogClass)
    {
        _transport = transport;
        _class = fogClass;
    }

    /// <summary>Creates a resource using the current transport.</summary>
    public FogResource(string fogClass) : this(FogTransport.Current, fogClass) { }

    // ---- the shapes the generator emits -------------------------------------

    /// <summary>Every row, streamed.</summary>
    public IEnumerable<TEntity> List(
        FogListOptions options,
        Func<bool>? stopping = null,
        Action<string>? verbose = null,
        Action<string>? warning = null)
    {
        FogPager pager = new(_transport, _class, options, verbose, warning);
        foreach (JsonNode? row in pager.Rows(stopping))
        {
            yield return Materialize(row);
        }
    }

    /// <summary>One row by id.</summary>
    /// <remarks>
    /// No <c>.data</c> here, and the asymmetry is deliberate rather than an
    /// oversight: a fetch by id returns the bare object, because a single
    /// object response has no envelope to unwrap. Every other shape does take
    /// the envelope, which is exactly why this is easy to get wrong.
    /// </remarks>
    public TEntity Get(object id) =>
        Materialize(ParseNode(_transport.Send(new FogRequest($"{_class}/{id}"))));

    /// <summary>Creates a row.</summary>
    public TEntity Create(JsonObject body) =>
        Materialize(ParseNode(_transport.Send(new FogRequest(_class, "POST", body.ToJsonString(FogJson.Wire)))));

    /// <summary>Updates a row.</summary>
    /// <remarks>
    /// The <c>/edit</c> spelling, not the bare <c>PUT /{class}/{id}</c> that
    /// 1.6 documents. 1.5 serves only /edit and 1.6 serves both, so /edit is
    /// the one spelling that works everywhere.
    /// </remarks>
    public TEntity Update(object id, JsonObject body) =>
        Materialize(ParseNode(_transport.Send(
            new FogRequest($"{_class}/{id}/edit", "PUT", body.ToJsonString(FogJson.Wire)))));

    /// <summary>Deletes a row.</summary>
    public void Delete(object id) =>
        _transport.Send(new FogRequest($"{_class}/{id}/delete", "DELETE"));

    /// <summary>Rows matching a search term.</summary>
    /// <remarks>
    /// Not paged, and cannot be. search builds its where clause in PHP from the
    /// ids it matched, and never calls paginate(), so there is no nextUrl to
    /// follow and a request filter cannot narrow it further.
    /// </remarks>
    public IEnumerable<TEntity> Search(string term)
    {
        FogEnvelope page = FogEnvelope.Parse(
            _transport.Send(new FogRequest($"{_class}/search/{Uri.EscapeDataString(term)}")));
        return page.Rows.Select(Materialize);
    }

    /// <summary>Queues a task against a row.</summary>
    public void Task(object id, JsonObject body) =>
        _transport.Send(new FogRequest($"{_class}/{id}/task", "POST", body.ToJsonString(FogJson.Wire)));

    /// <summary>Cancels a row's active task.</summary>
    public void Cancel(object id) =>
        _transport.Send(new FogRequest($"{_class}/{id}/cancel", "DELETE"));

    /// <summary>Rows with something active right now.</summary>
    public IEnumerable<TEntity> Active()
    {
        FogEnvelope page = FogEnvelope.Parse(_transport.Send(new FogRequest($"{_class}/current")));
        return page.Rows.Select(Materialize);
    }

    // ---- folded onto the list cmdlet as switches ----------------------------

    /// <summary>How many rows there are.</summary>
    public long Count(string? filter = null)
    {
        FogResponse response = _transport.Send(new FogRequest(WithFilter($"{_class}/count", filter)));
        JsonNode? node = response.IsEmpty ? null : JsonNode.Parse(response.Body);
        if (node is JsonObject obj && obj.TryGetPropertyValue("total", out JsonNode? total))
        {
            return FogRead.Int(total) ?? 0;
        }
        return 0;
    }

    /// <summary>Every row's id and name.</summary>
    /// <remarks>Unbounded server side; there is no LIMIT on this route and no envelope.</remarks>
    public IEnumerable<JsonNode?> Names(string? filter = null) =>
        FogEnvelope.Parse(_transport.Send(new FogRequest(WithFilter($"{_class}/names", filter)))).Rows;

    /// <summary>Every row's id.</summary>
    public IEnumerable<JsonNode?> Ids(string? filter = null) =>
        FogEnvelope.Parse(_transport.Send(new FogRequest(WithFilter($"{_class}/ids", filter)))).Rows;

    /// <summary>Creates a row if it is not there, updates it if it is.</summary>
    /// <remarks>
    /// Matches on the natural key rather than an id, because an upsert cannot
    /// know an id for a row that may not exist yet.
    /// </remarks>
    public FogResponse Join(JsonObject body) =>
        _transport.Send(new FogRequest($"{_class}/join", "PUT", body.ToJsonString(FogJson.Wire)));

    // ---- plumbing -----------------------------------------------------------

    private static string WithFilter(string path, string? filter) =>
        string.IsNullOrEmpty(filter) ? path : $"{path}?filter={filter}";

    private static JsonNode? ParseNode(FogResponse response) =>
        response.IsEmpty ? null : JsonNode.Parse(response.Body);

    private static TEntity Materialize(JsonNode? node)
    {
        if (node is null) { return new TEntity(); }
        return JsonSerializer.Deserialize<TEntity>(node, FogJson.Wire) ?? new TEntity();
    }
}
