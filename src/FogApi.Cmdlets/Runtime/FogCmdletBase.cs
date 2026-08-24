using System.Collections;
using System.Management.Automation;
using System.Text.Json.Nodes;
using FogApi.Models;

namespace FogApi.Cmdlets;

/// <summary>
/// What every generated cmdlet inherits: the transport, the payload rule, and
/// cancellation.
/// </summary>
/// <remarks>
/// The generated cmdlets carry attributes and parameters and no body at all.
/// Everything they DO lives here or in one of the shape bases, so a change to
/// how FogApi talks to FOG is one edit rather than 161.
/// </remarks>
public abstract class FogCmdletBase<TEntity> : PSCmdlet where TEntity : FogEntity, new()
{
    private readonly CancellationTokenSource _cts = new();

    /// <summary>The route class, e.g. <c>printer</c>. Generated per cmdlet.</summary>
    protected abstract string FogClass { get; }

    /// <summary>The resource this cmdlet acts through.</summary>
    protected FogResource<TEntity> Resource => new(FogTransport.Current, FogClass);

    /// <summary>The fields this entity declares.</summary>
    private static readonly FogFieldMap Fields = new TEntity().Map;

    /// <summary>Cancels the in-flight request.</summary>
    /// <remarks>
    /// StopProcessing runs on a DIFFERENT thread from ProcessRecord, so a
    /// token is the only safe channel. Do not touch cmdlet state from here.
    /// </remarks>
    protected override void StopProcessing() => _cts.Cancel();

    /// <summary>True once the pipeline has been asked to stop.</summary>
    protected bool IsStopping => _cts.IsCancellationRequested || Stopping;

    /// <summary>
    /// The request body: only the parameters the caller actually bound.
    /// </summary>
    /// <remarks>
    /// FOG's edit route MERGES, so a field the body does not mention is left
    /// alone. Sending an unbound parameter as its default -- "" or 0 -- would
    /// therefore overwrite a real value with nothing. That is data loss, and it
    /// is why this reads BoundParameters rather than the properties.
    /// <para>
    /// -Settings merges last and wins, so a caller can reach a field this
    /// build does not model without the named parameters fighting them for it.
    /// </para>
    /// </remarks>
    protected JsonObject BuildPayload(Hashtable? settings)
    {
        JsonObject body = new();

        // BoundParameters is a Dictionary<string, object>, not a Hashtable, so
        // this enumerates KeyValuePair rather than DictionaryEntry. The
        // -Settings loop below really is a Hashtable and really does.
        foreach (KeyValuePair<string, object> entry in MyInvocation.BoundParameters)
        {
            string name = entry.Key;
            FogField? field = Fields[name];
            // Common parameters, -Settings, -id and the paging switches are all
            // bound but are not fields.
            if (field is null || field.ReadOnly) { continue; }
            body[field.Name] = field.ToWire(entry.Value);
        }

        if (settings is not null)
        {
            foreach (DictionaryEntry entry in settings)
            {
                string name = (string)entry.Key;
                FogField? field = Fields[name];
                body[name] = field is null
                    ? JsonValue.Create(entry.Value?.ToString())
                    : field.ToWire(entry.Value);
            }
        }

        return body;
    }

    /// <summary>Unwraps an id, an object with an id, or leaves it alone.</summary>
    protected static object ResolveId(object id)
        => new FogObjectRefTransformAttribute().Transform(null!, id);

    /// <summary>Writes rows, stopping when the pipeline asks.</summary>
    protected void WriteRows(IEnumerable<TEntity> rows)
    {
        foreach (TEntity row in rows)
        {
            if (IsStopping) { return; }
            WriteObject(row);
        }
    }

    /// <summary>Verbose writer the resource layer can call.</summary>
    protected Action<string> Verbose => m => WriteVerbose(m);

    /// <summary>Warning writer the resource layer can call.</summary>
    protected Action<string> Warn => m => WriteWarning(m);
}
