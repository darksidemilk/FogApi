using System.Text.Json.Nodes;

namespace FogApi;

/// <summary>How a list request should be paged.</summary>
public sealed class FogListOptions
{
    /// <summary>Stop after this many rows. 0 means every row.</summary>
    public int First { get; set; }

    /// <summary>Skip this many rows before the first one returned.</summary>
    public int Skip { get; set; }

    /// <summary>Rows to ask for per request.</summary>
    public int PageSize { get; set; } = 1000;

    /// <summary>Make one request and stop, however much is left.</summary>
    public bool NoAutoPage { get; set; }

    /// <summary>A server-side column filter, already encoded.</summary>
    public string? Filter { get; set; }
}

/// <summary>
/// Walks a FOG list from the first page to the last.
/// </summary>
/// <remarks>
/// <para>
/// The C# port of Get-FogPagedResult, with one behavioural change: it STREAMS.
/// The PowerShell version assembled every page into a list and returned one
/// envelope, so <c>Get-FogHost | Select -First 5</c> on a 10,000 host server
/// still walked all ten pages. Yielding per row lets -First stop the walk --
/// measured, a streaming producer under Select-Object -First 3 stopped after 3
/// of 1,000,000 iterations in 11ms.
/// </para>
/// <para>
/// The rules below are not obvious and each of them is load-bearing.
/// </para>
/// </remarks>
internal sealed class FogPager
{
    private const int MaxPages = 10_000;

    private readonly IFogTransport _transport;
    private readonly string _path;
    private readonly FogListOptions _options;
    private readonly Action<string>? _verbose;
    private readonly Action<string>? _warning;

    public FogPager(
        IFogTransport transport,
        string path,
        FogListOptions options,
        Action<string>? verbose = null,
        Action<string>? warning = null)
    {
        _transport = transport;
        _path = path;
        _options = options;
        _verbose = verbose;
        _warning = warning;
    }

    /// <summary>Every row, one page at a time.</summary>
    public IEnumerable<JsonNode?> Rows(Func<bool>? stopping = null)
    {
        int start = Math.Max(0, _options.Skip);
        int pageSize = _options.PageSize > 0 ? _options.PageSize : 1000;
        int emitted = 0;
        int skipped = 0;
        int pageNumber = 0;
        bool serverPaged = false;

        while (true)
        {
            if (stopping?.Invoke() == true) { yield break; }
            pageNumber++;

            string uri = BuildPageUri(start, pageSize);
            FogEnvelope page = FogEnvelope.Parse(_transport.Send(new FogRequest(uri)));

            if (pageNumber == 1)
            {
                serverPaged = page.ServerPaged;
                if (!serverPaged)
                {
                    _verbose?.Invoke("server did not page this response; treating it as a complete 1.5 style list");
                }
            }

            IReadOnlyList<JsonNode?> rows = page.Rows;
            foreach (JsonNode? row in rows)
            {
                if (stopping?.Invoke() == true) { yield break; }

                // 1.5 ignores the query string entirely, so Skip has to be
                // honoured here rather than through the start param.
                if (!serverPaged && skipped < _options.Skip) { skipped++; continue; }

                yield return row;
                emitted++;
                if (_options.First > 0 && emitted >= _options.First) { yield break; }
            }

            if (!serverPaged || _options.NoAutoPage) { yield break; }

            // Termination is nextUrl and nothing else.
            //
            // recordsFiltered is not used: the site plugin rewrites it to the
            // post-scoping count for a site-restricted user, which makes it a
            // floor rather than a total.
            //
            // truncated is not used: the server only sets it when IT imposed
            // the cap, which never happens once we send our own paging params.
            if (string.IsNullOrEmpty(page.NextUrl)) { yield break; }

            // nextUrl set but the page came back empty. Following it would
            // loop forever on a server that always answers with a link.
            if (rows.Count == 0) { yield break; }

            if (pageNumber >= MaxPages)
            {
                _warning?.Invoke($"stopped after {MaxPages} pages as a safety limit; the result may be incomplete");
                yield break;
            }

            // Advance by rows RETURNED, not by the length requested. An ?expand
            // request has its page size clamped to EXPAND_MAX_ITEMS server side,
            // so a short page does not mean the end of the data -- and advancing
            // by the requested length would skip everything in between.
            start += rows.Count;
        }
    }

    private string BuildPageUri(int start, int pageSize)
    {
        // '&' when the path already carries a query string, which it does
        // whenever a filter was supplied. Hardcoding '?' produced
        // tasklog?filter=x?start=0, which the server reads as a filter VALUE of
        // "x?start=0" and rejects as an unknown field.
        string path = _path;
        if (!string.IsNullOrEmpty(_options.Filter))
        {
            path += (path.Contains('?') ? '&' : '?') + $"filter={_options.Filter}";
        }
        char join = path.Contains('?') ? '&' : '?';
        return $"{path}{join}start={start}&length={pageSize}";
    }
}
