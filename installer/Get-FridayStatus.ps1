[CmdletBinding()]
param(
  [string]$InstallRoot = 'D:\Friday',
  [string]$DataDirectory = 'D:\FridayData'
)

Set-StrictMode -Version Latest
$activePath = Join-Path $InstallRoot 'runtime\active.json'
if (-not (Test-Path -LiteralPath $activePath)) { return [PSCustomObject]@{ installed = $false; running = $false } }
$active = Get-Content -LiteralPath $activePath -Raw | ConvertFrom-Json
$configuration = Get-Content -LiteralPath (Join-Path $DataDirectory 'config\instance.json') -Raw | ConvertFrom-Json
$healthUri = ([string]$configuration.publicOrigin).TrimEnd('/') + '/api/health'
try { $health = Invoke-RestMethod -Uri $healthUri -TimeoutSec 3 }
catch { $health = $null }
[PSCustomObject]@{
  installed = $true
  running = [bool]$health
  activeIdentity = [string]$active.identity
  health = $health
  releasePath = [string]$active.releasePath
}
