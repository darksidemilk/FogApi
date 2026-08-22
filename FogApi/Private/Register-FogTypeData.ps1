function Register-FogTypeData {
<#
    .SYNOPSIS
    Registers Extended Type System type data for FOG object types.

    .DESCRIPTION
    This is how FogApi models FOG objects: a type name stamped onto the object the
    server actually returned, with display sets and methods hung off that name via
    type data. Real PowerShell classes were prototyped against this and lost -- see
    CONTEXT-api-coverage-plan.md, "Typed objects", for the comparison and why.

    The short version: a class has to declare its fields, and the OpenAPI schema
    does not describe the whole response (a host is 39 fields against 30 declared),
    so a class either drops the difference or relocates it to a catch-all and breaks
    every existing caller's property paths. Type data asserts nothing about fields,
    so nothing moves and nothing is lost.

    Type names are namespaced under 'FogApi.' on purpose. Type data is registered
    into the session's type table, not the module's, so it outlives Remove-Module
    and an unqualified 'Host' would be a land grab on a very common word.

    Called once from FogApi.psm1 at import, and re-emitted at the end of the built
    psm1 by invoke-modulebuild.ps1 because that file is generated and does not
    inherit the source psm1's body. -Force on every registration makes a re-import
    idempotent rather than an error.
#>
    [CmdletBinding()]
    param()

    process {
        # A host response carries 39 fields. A default table of all of them is
        # unreadable, which is the actual discoverability problem -- so name the
        # four that identify a host and let Format-List show the rest on request.
        Update-TypeData -Force -TypeName 'FogApi.Host' `
            -DefaultDisplayPropertySet id, name, description, ip

        Update-TypeData -Force -TypeName 'FogApi.Host' -MemberType ScriptMethod `
            -MemberName ToString -Value { '{0} ({1})' -f $this.name, $this.id }

        Update-TypeData -Force -TypeName 'FogApi.Host' -MemberType ScriptMethod `
            -MemberName Refresh -Value {
                Get-FogHost -hostID $this.id
            }

        Update-TypeData -Force -TypeName 'FogApi.Host' -MemberType ScriptMethod `
            -MemberName Deploy -Value {
                New-FogObject -type objecttasktype -coreTaskObject host -taskTypeID 1 -IDofObject $this.id
            }

        Update-TypeData -Force -TypeName 'FogApi.Host' -MemberType ScriptMethod `
            -MemberName Cancel -Value {
                Remove-FogObject -type objectactivetasktype -coreActiveTaskObject task -IDofObject $this.id
            }

        # The kind of convenience a class would need a real property for: reach
        # through to the joined inventory without the caller knowing it is joined.
        Update-TypeData -Force -TypeName 'FogApi.Host' -MemberType ScriptProperty `
            -MemberName SysUuid -Value { $this.inventory.sysuuid }
    }
}
