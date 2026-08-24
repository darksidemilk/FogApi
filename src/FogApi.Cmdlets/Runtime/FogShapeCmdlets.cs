using System.Collections;
using System.Management.Automation;
using System.Text.Json.Nodes;
using FogApi.Models;

namespace FogApi.Cmdlets;

/// <summary>
/// Gets rows: by id, by name, all of them, or just a count / names / ids.
/// </summary>
/// <remarks>
/// The <c>list</c> and <c>indiv</c> route shapes are one cmdlet, and
/// <c>count</c>, <c>names</c> and <c>ids</c> are folded onto it as switches
/// rather than being three more cmdlets nobody would look for.
/// </remarks>
public abstract class FogGetCmdlet<TEntity> : FogCmdletBase<TEntity> where TEntity : FogEntity, new()
{
    /// <summary>The id of one row. Accepts an id, or an object with an id.</summary>
    [Parameter(ParameterSetName = "byId", Mandatory = true, Position = 0,
               ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
    [FogObjectRefTransform]
    [Alias("IDofObject")]
    public object? id { get; set; }

    /// <summary>Return every row. The default with no parameters.</summary>
    [Parameter(ParameterSetName = "all")]
    public SwitchParameter All { get; set; }

    /// <summary>Stop after this many rows.</summary>
    [Parameter(ParameterSetName = "all")]
    public int First { get; set; }

    /// <summary>Skip this many rows.</summary>
    [Parameter(ParameterSetName = "all")]
    public int Skip { get; set; }

    /// <summary>Rows per request.</summary>
    [Parameter(ParameterSetName = "all")]
    public int PageSize { get; set; } = 1000;

    /// <summary>Make one request and stop.</summary>
    [Parameter(ParameterSetName = "all")]
    public SwitchParameter NoAutoPage { get; set; }

    /// <summary>A server-side column filter, as <c>field=value</c>.</summary>
    [Parameter(ParameterSetName = "all")]
    [Parameter(ParameterSetName = "count")]
    [Parameter(ParameterSetName = "names")]
    [Parameter(ParameterSetName = "ids")]
    public string? Filter { get; set; }

    /// <summary>Return how many rows there are, not the rows.</summary>
    [Parameter(ParameterSetName = "count", Mandatory = true)]
    public SwitchParameter Count { get; set; }

    /// <summary>Return each row's id and name only.</summary>
    [Parameter(ParameterSetName = "names", Mandatory = true)]
    public SwitchParameter NamesOnly { get; set; }

    /// <summary>Return each row's id only.</summary>
    [Parameter(ParameterSetName = "ids", Mandatory = true)]
    public SwitchParameter IdsOnly { get; set; }

    /// <inheritdoc/>
    protected override void ProcessRecord()
    {
        switch (ParameterSetName)
        {
            case "byId":
                WriteObject(Resource.Get(ResolveId(id!)));
                return;

            case "count":
                WriteObject(Resource.Count(Filter));
                return;

            case "names":
                WriteObject(Resource.Names(Filter).Select(FogJson.ToPowerShell), enumerateCollection: true);
                return;

            case "ids":
                WriteObject(Resource.Ids(Filter).Select(FogJson.ToPowerShell), enumerateCollection: true);
                return;

            default:
                FogListOptions options = new()
                {
                    First = First,
                    Skip = Skip,
                    PageSize = PageSize,
                    NoAutoPage = NoAutoPage.IsPresent,
                    Filter = Filter,
                };
                WriteRows(Resource.List(options, () => IsStopping, Verbose, Warn));
                return;
        }
    }
}

/// <summary>Finds rows matching a search term.</summary>
public abstract class FogFindCmdlet<TEntity> : FogCmdletBase<TEntity> where TEntity : FogEntity, new()
{
    /// <summary>What to search for.</summary>
    [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]
    [ValidateNotNullOrEmpty]
    [Alias("stringToSearch")]
    public string SearchTerm { get; set; } = string.Empty;

    /// <inheritdoc/>
    protected override void ProcessRecord() => WriteRows(Resource.Search(SearchTerm));
}

/// <summary>Creates a row.</summary>
public abstract class FogNewCmdlet<TEntity> : FogCmdletBase<TEntity> where TEntity : FogEntity, new()
{
    /// <summary>Fields this build does not model, or overrides for ones it does.</summary>
    [Parameter]
    public Hashtable? settings { get; set; }

    /// <inheritdoc/>
    protected override void ProcessRecord()
    {
        JsonObject body = BuildPayload(settings);
        if (!ShouldProcess($"{FogClass}", "create")) { return; }
        WriteObject(Resource.Create(body));
    }
}

/// <summary>Updates a row.</summary>
public abstract class FogUpdateCmdlet<TEntity> : FogCmdletBase<TEntity> where TEntity : FogEntity, new()
{
    /// <summary>Which row. Accepts an id, or an object with an id.</summary>
    [Parameter(Mandatory = true, Position = 0,
               ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
    [FogObjectRefTransform]
    [Alias("IDofObject")]
    public object id { get; set; } = null!;

    /// <summary>Fields this build does not model, or overrides for ones it does.</summary>
    [Parameter]
    public Hashtable? settings { get; set; }

    /// <inheritdoc/>
    protected override void ProcessRecord()
    {
        object target = ResolveId(id);
        JsonObject body = BuildPayload(settings);

        if (body.Count == 0)
        {
            // Sending an empty body would be a no-op at best. Saying so beats
            // a silent success that looks like the update worked.
            WriteWarning($"no fields to update on {FogClass} {target}; nothing was sent");
            return;
        }

        if (!ShouldProcess($"{FogClass} {target}", "update")) { return; }
        WriteObject(Resource.Update(target, body));
    }
}

/// <summary>Deletes a row.</summary>
public abstract class FogRemoveCmdlet<TEntity> : FogCmdletBase<TEntity> where TEntity : FogEntity, new()
{
    /// <summary>Which row. Accepts an id, or an object with an id.</summary>
    [Parameter(Mandatory = true, Position = 0,
               ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
    [FogObjectRefTransform]
    [Alias("IDofObject")]
    public object id { get; set; } = null!;

    /// <inheritdoc/>
    protected override void ProcessRecord()
    {
        object target = ResolveId(id);
        if (!ShouldProcess($"{FogClass} {target}", "delete")) { return; }
        Resource.Delete(target);
    }
}

/// <summary>Queues a task against a row.</summary>
public abstract class FogStartTaskCmdlet<TEntity> : FogCmdletBase<TEntity> where TEntity : FogEntity, new()
{
    /// <summary>Which row. Accepts an id, or an object with an id.</summary>
    [Parameter(Mandatory = true, Position = 0,
               ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
    [FogObjectRefTransform]
    [Alias("IDofObject")]
    public object id { get; set; } = null!;

    /// <summary>The task body.</summary>
    /// <remarks>
    /// Wake-on-lan is this route with <c>wol</c> set, not a route of its own.
    /// </remarks>
    [Parameter(Position = 1)]
    [Alias("TaskRequest")]
    public Hashtable? request { get; set; }

    /// <inheritdoc/>
    protected override void ProcessRecord()
    {
        object target = ResolveId(id);
        JsonObject body = new();
        if (request is not null)
        {
            foreach (DictionaryEntry entry in request)
            {
                body[(string)entry.Key] = JsonValue.Create(entry.Value?.ToString());
            }
        }
        if (!ShouldProcess($"{FogClass} {target}", "queue a task")) { return; }
        Resource.Task(target, body);
    }
}

/// <summary>Cancels a row's active task.</summary>
public abstract class FogStopTaskCmdlet<TEntity> : FogCmdletBase<TEntity> where TEntity : FogEntity, new()
{
    /// <summary>Which row. Accepts an id, or an object with an id.</summary>
    [Parameter(Mandatory = true, Position = 0,
               ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
    [FogObjectRefTransform]
    [Alias("IDofObject")]
    public object id { get; set; } = null!;

    /// <inheritdoc/>
    protected override void ProcessRecord()
    {
        object target = ResolveId(id);
        if (!ShouldProcess($"{FogClass} {target}", "cancel the active task")) { return; }
        Resource.Cancel(target);
    }
}

/// <summary>Gets the rows with something active right now.</summary>
public abstract class FogGetActiveCmdlet<TEntity> : FogCmdletBase<TEntity> where TEntity : FogEntity, new()
{
    /// <inheritdoc/>
    protected override void ProcessRecord() => WriteRows(Resource.Active());
}
