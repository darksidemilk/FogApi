using System.Text.Json.Nodes;
using System.Text.Json.Serialization;

namespace FogApi.Models;

/// <summary>
/// A FOG printer, from the <c>printers</c> table.
/// </summary>
/// <remarks>
/// HAND-WRITTEN FOR NOW, and written the way the emitter will write it, so the
/// generated shape is settled against a compiler before 51 of these exist.
/// Everything here comes from <c>schemas.printer</c> in spec/fog-api-spec.json:
/// the field list, the wire types, the maxLengths and the column names.
/// <para>
/// Responses may also carry <c>hosts</c>, which is not a column and is not in
/// properties. It arrives through <see cref="FogEntity"/>'s dynamic bag, so
/// <c>$p.hosts</c> resolves without this type declaring it.
/// </para>
/// </remarks>
[JsonConverter(typeof(FogEntityConverter<FogPrinter>))]
public sealed class FogPrinter : FogEntity
{
    /// <summary>The fields FOG declares for a printer.</summary>
    public static readonly FogFieldMap FieldMap = new(
        new FogField("id", "pID", FogWire.Int, ReadOnly: true),
        new FogField("name", "pAlias", FogWire.String, MaxLength: 250),
        new FogField("description", "pDesc", FogWire.String),
        new FogField("port", "pPort", FogWire.String),
        new FogField("file", "pDefFile", FogWire.String),
        new FogField("model", "pModel", FogWire.String, MaxLength: 250),
        new FogField("config", "pConfig", FogWire.String, MaxLength: 10),
        new FogField("configFile", "pConfigFile", FogWire.String, MaxLength: 255),
        new FogField("ip", "pIP", FogWire.String, MaxLength: 255),
        new FogField("pAnon2", "pAnon2", FogWire.String, MaxLength: 10),
        new FogField("pAnon3", "pAnon3", FogWire.String, MaxLength: 10),
        new FogField("pAnon4", "pAnon4", FogWire.String, MaxLength: 10),
        new FogField("pAnon5", "pAnon5", FogWire.String, MaxLength: 10));

    /// <inheritdoc/>
    internal override FogFieldMap Map => FieldMap;

    /// <inheritdoc/>
    internal override string FogClass => "printer";

    // Lowercase property names, deliberately. They are the parameter names the
    // cmdlets expose and the keys FOG sends, and matching both means neither
    // the wire nor the caller has to be translated. C# permits it.

    private long? _id;
    /// <summary>Primary key. <c>pID</c>.</summary>
    public long? id { get => _id; set => Set(ref _id, value); }

    private string? _name;
    /// <summary>Display name, unique. <c>pAlias</c>, varchar(250).</summary>
    public string? name { get => _name; set => Set(ref _name, value); }

    private string? _description;
    /// <summary><c>pDesc</c>.</summary>
    public string? description { get => _description; set => Set(ref _description, value); }

    private string? _port;
    /// <summary><c>pPort</c>.</summary>
    public string? port { get => _port; set => Set(ref _port, value); }

    private string? _file;
    /// <summary>Default driver file. <c>pDefFile</c>.</summary>
    public string? file { get => _file; set => Set(ref _file, value); }

    private string? _model;
    /// <summary><c>pModel</c>, varchar(250).</summary>
    public string? model { get => _model; set => Set(ref _model, value); }

    private string? _config;
    /// <summary><c>pConfig</c>, varchar(10).</summary>
    public string? config { get => _config; set => Set(ref _config, value); }

    private string? _configFile;
    /// <summary><c>pConfigFile</c>, varchar(255).</summary>
    public string? configFile { get => _configFile; set => Set(ref _configFile, value); }

    private string? _ip;
    /// <summary><c>pIP</c>, varchar(255).</summary>
    public string? ip { get => _ip; set => Set(ref _ip, value); }

    private string? _pAnon2;
    /// <summary><c>pAnon2</c>, varchar(10).</summary>
    public string? pAnon2 { get => _pAnon2; set => Set(ref _pAnon2, value); }

    private string? _pAnon3;
    /// <summary><c>pAnon3</c>, varchar(10).</summary>
    public string? pAnon3 { get => _pAnon3; set => Set(ref _pAnon3, value); }

    private string? _pAnon4;
    /// <summary><c>pAnon4</c>, varchar(10).</summary>
    public string? pAnon4 { get => _pAnon4; set => Set(ref _pAnon4, value); }

    private string? _pAnon5;
    /// <summary><c>pAnon5</c>, varchar(10).</summary>
    public string? pAnon5 { get => _pAnon5; set => Set(ref _pAnon5, value); }

    /// <inheritdoc/>
    public override object? ReadDeclared(string field) => field.ToLowerInvariant() switch
    {
        "id" => id,
        "name" => name,
        "description" => description,
        "port" => port,
        "file" => file,
        "model" => model,
        "config" => config,
        "configfile" => configFile,
        "ip" => ip,
        "panon2" => pAnon2,
        "panon3" => pAnon3,
        "panon4" => pAnon4,
        "panon5" => pAnon5,
        _ => null,
    };

    /// <inheritdoc/>
    public override bool SetDeclared(string field, JsonNode? value)
    {
        switch (field.ToLowerInvariant())
        {
            case "id": id = FogRead.Int(value); return true;
            case "name": name = FogRead.String(value); return true;
            case "description": description = FogRead.String(value); return true;
            case "port": port = FogRead.String(value); return true;
            case "file": file = FogRead.String(value); return true;
            case "model": model = FogRead.String(value); return true;
            case "config": config = FogRead.String(value); return true;
            case "configfile": configFile = FogRead.String(value); return true;
            case "ip": ip = FogRead.String(value); return true;
            case "panon2": pAnon2 = FogRead.String(value); return true;
            case "panon3": pAnon3 = FogRead.String(value); return true;
            case "panon4": pAnon4 = FogRead.String(value); return true;
            case "panon5": pAnon5 = FogRead.String(value); return true;
            default: return false;
        }
    }
}
