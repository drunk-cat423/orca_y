[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('bailian', 'deepseek_official', 'redromance_claude', 'codex_subscription_claude')]
    [string]$Provider,

    [string]$ConfigRoot,

    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._:\[\]/-]*$')]
    [string]$Model,

    [ValidateSet('low', 'medium', 'high', 'xhigh', 'max')]
    [string]$Effort,

    [switch]$Check
)

$ErrorActionPreference = 'Stop'
$orcaRoot = Join-Path $env:LOCALAPPDATA 'Orca'
$directory = @{
    bailian = 'bailian'
    deepseek_official = 'deepseek-official'
    redromance_claude = 'redromance-claude'
    codex_subscription_claude = 'codex-subscription-claude'
}[$Provider]
$relativeSettings = "$directory/settings.json"

if ($ConfigRoot) {
    $settingsPath = Join-Path $ConfigRoot $relativeSettings
} else {
    $settingsPath = Join-Path (Join-Path $orcaRoot 'provider-settings') $relativeSettings
    if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
        $t3Root = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.t3/userdata/provider-homes'
        $settingsPath = Join-Path $t3Root $relativeSettings
    }
}
if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
    throw "Settings file for $Provider is missing. See docs/providers.md."
}
$settingsPath = (Resolve-Path -LiteralPath $settingsPath).ProviderPath
try {
    $settings = Get-Content -Raw -Encoding UTF8 -LiteralPath $settingsPath | ConvertFrom-Json
} catch {
    throw "Settings file for $Provider could not be read as JSON."
}

$endpoint = $null
if (-not [uri]::TryCreate($settings.env.ANTHROPIC_BASE_URL, [UriKind]::Absolute, [ref]$endpoint) -or
    $endpoint.Scheme -notin @('https', 'http') -or
    -not ($settings.env.ANTHROPIC_AUTH_TOKEN -or $settings.env.ANTHROPIC_API_KEY)) {
    throw "Missing HTTP endpoint or local Claude credential for $Provider."
}
if (-not $Model) { $Model = $settings.env.ANTHROPIC_MODEL }
if ($Model -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._:\[\]/-]*$') {
    throw "Missing or invalid model ID for $Provider."
}
if ($Provider -eq 'codex_subscription_claude') {
    if (-not $endpoint.IsLoopback) { throw 'The Codex bridge must be a local loopback endpoint.' }
    $healthUrl = $endpoint.GetLeftPart([UriPartial]::Authority) + '/healthz'
    try {
        $health = Invoke-WebRequest -UseBasicParsing -Uri $healthUrl -TimeoutSec 3 -MaximumRedirection 0
        if ([int]$health.StatusCode -ne 200) { throw 'Bridge is not ready.' }
    } catch {
        throw 'The local Codex bridge is unavailable. See docs/providers.md.'
    }
    if ($Model -match 'astra' -and $Effort -ne 'low') { $Effort = 'medium' }
}

$commands = Get-Command claude.cmd, claude.exe -CommandType Application -ErrorAction SilentlyContinue
$claude = $commands | Select-Object -First 1
if (-not $claude) { throw 'Claude Code CLI was not found on PATH.' }

# The provider settings file supplies credentials directly to Claude.
$overrideNames = @(
    'ANTHROPIC_API_KEY'
    'ANTHROPIC_AUTH_TOKEN'
    'ANTHROPIC_CUSTOM_HEADERS'
    'ANTHROPIC_DEFAULT_OPUS_MODEL'
    'ANTHROPIC_DEFAULT_SONNET_MODEL'
    'ANTHROPIC_DEFAULT_HAIKU_MODEL'
    'CLAUDE_CODE_EFFORT_LEVEL'
    'CLAUDE_CODE_OAUTH_TOKEN'
    'CLAUDE_CODE_SUBAGENT_MODEL'
    'CLAUDE_CODE_USE_BEDROCK'
    'CLAUDE_CODE_USE_VERTEX'
    'CLAUDE_CODE_USE_FOUNDRY'
) + @($settings.env.PSObject.Properties.Name) + @('CLAUDE_CONFIG_DIR')
$savedEnvironment = @{}
foreach ($name in $overrideNames) {
    if (-not $savedEnvironment.ContainsKey($name)) {
        $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    }
    [Environment]::SetEnvironmentVariable($name, $null, 'Process')
}

try {
    $sessionDirectory = Join-Path (Join-Path $orcaRoot 'provider-sessions') $directory
    New-Item -ItemType Directory -Force -Path $sessionDirectory | Out-Null
    $env:CLAUDE_CONFIG_DIR = $sessionDirectory
    $launchArguments = @('--settings', $settingsPath)

    if ($Check) {
        try {
            $authOutput = & $claude.Source @launchArguments auth status --json 2>$null
            $authExitCode = $LASTEXITCODE
            $auth = $authOutput | ConvertFrom-Json
            if ($authExitCode -ne 0 -or -not $auth.loggedIn) { throw 'Credential check failed.' }
        } catch {
            throw "Claude Code did not recognize a local credential for $Provider."
        }
        Write-Output "$Provider | local auth OK | model $Model"
    } else {
        $launchArguments += @('--model', $Model)
        if ($Effort) { $launchArguments += @('--effort', $Effort) }
        & $claude.Source @launchArguments
        exit $LASTEXITCODE
    }
} finally {
    foreach ($name in $savedEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process')
    }
}
