<#
GENERATED FILE. Do not edit. Rebuild with spec/tools/New-FogInputClass.ps1.

FogTaskRequest is the body of POST /{class}/{id}/task, taken from FOG's own
OpenAPI document. The server's words for it:

  Body accepts taskTypeID, taskName, shutdown, debug, deploySnapins, passreset, sessionjoin and wol. Wake-on-lan is this route with wol set, not a route of its own.

Fields, and the PowerShell type each maps to:

    taskTypeID     [Nullable[int]]
    taskName       [string]
    shutdown       [Nullable[bool]]
    debug          [Nullable[bool]]
    deploySnapins  [Nullable[int]]
    passreset      [string]
    sessionjoin    [Nullable[bool]]
    wol            [Nullable[bool]]

A field left $null is omitted from the body entirely. That is the reason the
value types are Nullable -- a plain [bool] would default to $false and send a
deliberate "0" for a field the caller never mentioned.

Use it like any other object:

    $t = [FogTaskRequest]@{ taskTypeID = 1; taskName = 'deploy'; shutdown = $false }
    Send-FogImage -hostName somehost -TaskRequest $t

Or from a hashtable, which validates the field names as it converts:

    $t = [FogTaskRequest]::FromHashtable(@{ taskTypeID = 13; deploySnapins = -1 })

Three things about this class are deliberate and must survive regeneration:

  * There is no single-argument [object] constructor. A class that has one
    accepts ANY object, including [pscustomobject]@{nope=1}, because
    PowerShell's conversion finds it. FromHashtable() is the conversion path,
    and it rejects unknown fields.
  * The default constructor computes nothing. [FogTaskRequest]@{...} runs it
    before the hashtable properties are assigned, so derived state set there
    would be computed from empty values.
  * A caller writes [OutputType('FogTaskRequest')] -- the string. The type
    literal form does not resolve in a dot-sourced module and poisons the whole
    function, so even invoking it throws.
#>
class FogTaskRequest {
    [Nullable[int]]$taskTypeID
    [string]$taskName
    [Nullable[bool]]$shutdown
    [Nullable[bool]]$debug
    [Nullable[int]]$deploySnapins
    [string]$passreset
    [Nullable[bool]]$sessionjoin
    [Nullable[bool]]$wol

    # Anything the class does not model, merged over the body last. The same
    # escape hatch the generated cmdlets spell -settings, and the reason
    # isActive -- which the module has always sent and the document does not
    # declare -- still reaches the wire.
    [hashtable]$extra

    # Nothing derived here, on purpose. See the note above.
    FogTaskRequest() {}

    static [string[]] FieldNames() {
        return @('taskTypeID', 'taskName', 'shutdown', 'debug', 'deploySnapins', 'passreset', 'sessionjoin', 'wol')
    }

    static [FogTaskRequest] FromHashtable([hashtable]$values) {
        if ($null -eq $values) { throw [System.ArgumentNullException]::new('values') }
        $known = [FogTaskRequest]::FieldNames()
        $req = [FogTaskRequest]::new()
        $spill = @{}
        foreach ($key in $values.Keys) {
            if ($known -contains $key) {
                $req.$key = $values[$key]
            } else {
                # Unknown field names are the common typo, so they go to the
                # escape hatch rather than being dropped -- but say so, because
                # a misspelled taskTypeID is otherwise a silent no-op.
                Write-Verbose "FogTaskRequest: '$key' is not a declared task field; passing it through -extra"
                $spill[$key] = $values[$key]
            }
        }
        if ($spill.Count -gt 0) { $req.extra = $spill }
        return $req
    }

    # FOG accepts a JSON boolean here, but every shipped caller has always sent
    # "1"/"0" and a task is not the place to find out whether some 1.5-era
    # branch still depends on that. Rendering stays as it was.
    hidden static [string] Render([object]$value) {
        if ($value -is [bool]) { return $(if ($value) { '1' } else { '0' }) }
        return "$value"
    }

    # The FOG 1.6 body: the declared fields the caller actually set, plus
    # anything in -extra.
    [hashtable] ToBody() {
        $body = @{}
        foreach ($name in [FogTaskRequest]::FieldNames()) {
            $value = $this.$name
            if ($null -eq $value) { continue }
            if ($value -is [string] -and $value -eq '') { continue }
            $body[$name] = [FogTaskRequest]::Render($value)
        }
        if ($null -ne $this.extra) {
            foreach ($key in $this.extra.Keys) { $body[$key] = [FogTaskRequest]::Render($this.extra[$key]) }
        }
        return $body
    }

    # The FOG 1.5 body. 1.5 has no taskName, and spells two fields as the
    # scheduledtask columns they are stored in: other2 is deploySnapins and
    # other4 is wol.
    #
    # Send-FogImage, Receive-FogImage and Send-FogGroupTask have always put the
    # DEBUG flag in other2 on this path, which does not match that reading.
    # Whether 1.5 ever honoured it is not answerable from a 1.6 server, so this
    # reproduces today's bytes rather than quietly changing what a 1.5 install
    # sends. See CONTEXT-typed-objects-plan.md.
    [hashtable] ToLegacyBody() {
        $body = $this.ToBody()
        $body.Remove('taskName')
        foreach ($pair in @{ deploySnapins = 'other2'; wol = 'other4' }.GetEnumerator()) {
            if ($body.ContainsKey($pair.Key)) {
                $body[$pair.Value] = $body[$pair.Key]
                $body.Remove($pair.Key)
            }
        }
        return $body
    }

    [string] ToJson() { return ($this.ToBody() | ConvertTo-Json -Depth 5 -Compress) }
    [string] ToLegacyJson() { return ($this.ToLegacyBody() | ConvertTo-Json -Depth 5 -Compress) }

    # Picks the spelling for the server in front of you.
    [string] ToJsonForServer([bool]$isFogSixteen) {
        if ($isFogSixteen) { return $this.ToJson() }
        return $this.ToLegacyJson()
    }

    [string] ToString() {
        $type = $(if ($null -eq $this.taskTypeID) { '?' } else { $this.taskTypeID })
        if ([string]::IsNullOrEmpty($this.taskName)) { return "FogTaskRequest(taskTypeID=$type)" }
        return "FogTaskRequest(taskTypeID=$type, '$($this.taskName)')"
    }
}
