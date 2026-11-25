[CmdletBinding()]
param([string]$OrcaCli)

$ErrorActionPreference = 'Stop'
if (-not $OrcaCli) {
    $OrcaCli = $env:ORCA_CLI_COMMAND
}
if (-not $OrcaCli) {
    $OrcaCli = Join-Path $env:LOCALAPPDATA 'Programs/orca/resources/bin/orca.exe'
    if (-not (Test-Path -LiteralPath $OrcaCli -PathType Leaf)) {
        $cli = Get-Command orca.exe -CommandType Application -ErrorAction SilentlyContinue
        if (-not $cli) { throw 'Orca CLI was not found. See docs/windows.md.' }
        $OrcaCli = $cli.Source
    }
}

function Read-OrcaResult {
    param([string[]]$CommandArguments)

    $raw = & $OrcaCli @CommandArguments --environment local --json
    $exitCode = $LASTEXITCODE
    $reply = $raw | ConvertFrom-Json
    if ($exitCode -ne 0 -or -not $reply.ok) {
        throw ('Orca command failed: ' + ($CommandArguments -join ' ') + ' / ' + $reply.error.code)
    }
    return $reply.result
}

$status = Read-OrcaResult -CommandArguments @('status')
if (-not $status.app.running -or -not $status.runtime.reachable -or $status.runtime.state -ne 'ready') {
    throw 'The local Orca app and runtime are not ready. See docs/windows.md.'
}
$agents = Read-OrcaResult -CommandArguments @('agent', 'installed')
$repos = Read-OrcaResult -CommandArguments @('repo', 'list')

[pscustomobject]@{
    OrcaVersion = $status.runtime.appVersion
    Runtime = $status.runtime.state
    DetectedAgents = @($agents.agents | ForEach-Object { $_.id })
    RegisteredProjects = @($repos.repos | Select-Object displayName, kind, hiddenAt)
} | ConvertTo-Json -Depth 4
