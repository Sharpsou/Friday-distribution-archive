[CmdletBinding()]
param(
  [string]$InstallRoot = 'D:\Friday',
  [string]$DataDirectory = 'D:\FridayData',
  [switch]$Foreground,
  [switch]$RestartExisting,
  [ValidateRange(5, 120)][int]$HealthTimeoutSeconds = 45
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Set-FridayEnvironment {
  param([Parameter(Mandatory = $true)]$Configuration)

  $env:FRIDAY_DATA_DIR = $DataDirectory
  $env:FRIDAY_DATABASE_PATH = Join-Path $DataDirectory 'friday.sqlite'
  $env:FRIDAY_HOST = [string]$Configuration.host
  $env:FRIDAY_PORT = [string]$Configuration.port
  $env:FRIDAY_PUBLIC_ORIGIN = [string]$Configuration.publicOrigin
  $env:FRIDAY_TRUSTED_ORIGINS = @($Configuration.trustedOrigins) -join ','
  $env:FRIDAY_CHAT_ENABLED = ([string][bool]$Configuration.features.chatEnabled).ToLowerInvariant()
  $env:FRIDAY_CHAT_AXES_ENABLED = ([string][bool]$Configuration.features.chatAxesEnabled).ToLowerInvariant()
  $env:FRIDAY_CHAT_PIPELINE = [string]$Configuration.features.chatPipeline
  $robotConfigurationPath = Join-Path $DataDirectory 'robot\hub.json'
  $robotEnabledProperty = $Configuration.features.PSObject.Properties['robotEnabled']
  $robotUiEnabled = if ($robotEnabledProperty) {
    [bool]$robotEnabledProperty.Value
  }
  else {
    Test-Path -LiteralPath $robotConfigurationPath -PathType Leaf
  }
  $env:FRIDAY_ROBOT_UI_ENABLED = ([string]$robotUiEnabled).ToLowerInvariant()
  $env:FRIDAY_OLLAMA_URL = [string]$Configuration.ollama.url
  $env:FRIDAY_GROCERY_CLASSIFICATION_MODEL = [string]$Configuration.models.groceryClassification
  $env:FRIDAY_GROCERY_PHOTO_MODEL = [string]$Configuration.models.groceryPhoto

  if ($Configuration.tls.enabled) {
    $env:FRIDAY_TLS_CERT_PATH = [string]$Configuration.tls.certificatePath
    $env:FRIDAY_TLS_KEY_PATH = [string]$Configuration.tls.keyPath
  }
  else {
    Remove-Item Env:FRIDAY_TLS_CERT_PATH, Env:FRIDAY_TLS_KEY_PATH -ErrorAction SilentlyContinue
  }

  $tavilyPath = Join-Path $DataDirectory 'secrets\tavily-api-key'
  if (Test-Path -LiteralPath $tavilyPath) {
    $env:FRIDAY_TAVILY_API_KEY = (Get-Content -LiteralPath $tavilyPath -Raw).Trim()
  }

  $robotPath = $robotConfigurationPath
  $env:FRIDAY_ROBOT_MODE = 'disabled'
  if (Test-Path -LiteralPath $robotPath) {
    $robot = Get-Content -LiteralPath $robotPath -Raw | ConvertFrom-Json
    $env:FRIDAY_ROBOT_MODE = [string]$robot.mode
    if ($env:FRIDAY_ROBOT_MODE -eq 'alphabot2') {
      $env:FRIDAY_ROBOT_URL = [string]$robot.url
      $env:FRIDAY_ROBOT_TOKEN = [string]$robot.token
      if ($robot.wakeUrl -and $robot.wakeToken) {
        $env:FRIDAY_ROBOT_WAKE_URL = [string]$robot.wakeUrl
        $env:FRIDAY_ROBOT_WAKE_TOKEN = [string]$robot.wakeToken
      }
      $pythonPath = Join-Path $DataDirectory 'robot\localization-venv\Scripts\python.exe'
      if (Test-Path -LiteralPath $pythonPath) {
        $env:FRIDAY_ROBOT_PLACE_RECOGNITION_PYTHON = $pythonPath
        $env:FRIDAY_ROBOT_PLACE_RECOGNITION_WORKER_PATH = Join-Path $releaseRoot 'tools\robot-localization\place-worker.py'
      }
      else {
        $env:FRIDAY_ROBOT_PLACE_RECOGNITION_ENABLED = 'false'
      }
    }
  }
}

$activePath = Join-Path $InstallRoot 'runtime\active.json'
$configurationPath = Join-Path $DataDirectory 'config\instance.json'
if (-not (Test-Path -LiteralPath $activePath)) { throw "Release active absente : $activePath" }
if (-not (Test-Path -LiteralPath $configurationPath)) { throw "Configuration absente : $configurationPath" }
$active = Get-Content -LiteralPath $activePath -Raw | ConvertFrom-Json
$configuration = Get-Content -LiteralPath $configurationPath -Raw | ConvertFrom-Json
$releaseRoot = [string]$active.releasePath
$manifest = Get-Content -LiteralPath (Join-Path $releaseRoot 'manifest.json') -Raw | ConvertFrom-Json
$nodePath = Join-Path $releaseRoot 'runtime\node.exe'
$hubPath = Join-Path $releaseRoot ([string]$manifest.entrypoint -replace '/', '\')
if (-not (Test-Path -LiteralPath $nodePath)) { throw "Runtime Node absent : $nodePath" }
if (-not (Test-Path -LiteralPath $hubPath)) { throw "Hub absent : $hubPath" }

if ($RestartExisting) { & (Join-Path $InstallRoot 'installer\Stop-Friday.ps1') -InstallRoot $InstallRoot }
Set-FridayEnvironment -Configuration $configuration
$env:FRIDAY_RELEASE_VERSION = [string]$manifest.identity
$env:FRIDAY_WEB_ROOT = Join-Path $releaseRoot 'web'
$logDirectory = Join-Path $DataDirectory 'logs'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null

if ($Foreground) {
  Push-Location $releaseRoot
  try { & $nodePath $hubPath 1>> (Join-Path $logDirectory 'friday-hub.stdout.log') 2>> (Join-Path $logDirectory 'friday-hub.stderr.log'); exit $LASTEXITCODE }
  finally { Pop-Location }
}

$process = Start-Process -FilePath $nodePath -ArgumentList @($hubPath) -WorkingDirectory $releaseRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $logDirectory 'friday-hub.stdout.log') -RedirectStandardError (Join-Path $logDirectory 'friday-hub.stderr.log')
$healthUri = ([string]$configuration.publicOrigin).TrimEnd('/') + '/api/health'
$deadline = [DateTime]::UtcNow.AddSeconds($HealthTimeoutSeconds)
do {
  if ($process.HasExited) { throw "Le Hub s'est arrêté avec le code $($process.ExitCode)." }
  try { $health = Invoke-RestMethod -Uri $healthUri -TimeoutSec 2 }
  catch { $health = $null }
  if ($health -and $health.status -eq 'ok' -and $health.version -eq $manifest.identity) { return $health }
  Start-Sleep -Milliseconds 250
} while ([DateTime]::UtcNow -lt $deadline)
Stop-Process -Id $process.Id -ErrorAction SilentlyContinue
throw "Friday n'a pas répondu avec la version attendue sur $healthUri."
