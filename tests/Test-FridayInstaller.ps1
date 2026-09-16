Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('friday-installer-test-' + [Guid]::NewGuid().ToString('N'))
$installRoot = Join-Path $testRoot 'Friday'
$dataRoot = Join-Path $testRoot 'FridayData'

function Get-TestSha256 {
  param([Parameter(Mandatory = $true)][string]$LiteralPath)
  $stream = [IO.File]::OpenRead($LiteralPath)
  try {
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($algorithm.ComputeHash($stream)) -replace '-', '').ToLowerInvariant() }
    finally { $algorithm.Dispose() }
  }
  finally { $stream.Dispose() }
}

function New-TestPackage {
  param(
    [Parameter(Mandatory = $true)][string]$Identity,
    [Parameter(Mandatory = $true)][bool]$SourceDirty
  )
  $packageRoot = Join-Path $testRoot ($Identity -replace '[^A-Za-z0-9._+-]', '-')
  foreach ($relativePath in @('runtime\node.exe', 'web\index.html', 'hub\dist\main.js')) {
    $path = Join-Path $packageRoot $relativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    Set-Content -LiteralPath $path -Value "$Identity/$relativePath" -Encoding ascii
  }
  $files = @('runtime\node.exe', 'web\index.html', 'hub\dist\main.js') | ForEach-Object {
    $path = Join-Path $packageRoot $_
    [ordered]@{
      path = $_ -replace '\\', '/'
      size = (Get-Item -LiteralPath $path).Length
      sha256 = Get-TestSha256 -LiteralPath $path
    }
  }
  [ordered]@{
    format = 1
    product = 'Friday'
    version = 'test'
    identity = $Identity
    installerFormat = 1
    sourceDirty = $SourceDirty
    entrypoint = 'hub/dist/main.js'
    files = $files
  } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $packageRoot 'manifest.json') -Encoding utf8
  return $packageRoot
}

try {
  New-Item -ItemType Directory -Path (Join-Path $installRoot 'installer') -Force | Out-Null
  @'
param([string]$InstallRoot, [string]$DataDirectory, [switch]$RestartExisting)
$active = Get-Content -LiteralPath (Join-Path $InstallRoot 'runtime\active.json') -Raw | ConvertFrom-Json
if ([string]$active.identity -eq '0.1.0-alpha.3+broken') { throw 'SIMULATED_START_FAILURE' }
'@ | Set-Content -LiteralPath (Join-Path $installRoot 'installer\Start-Friday.ps1') -Encoding utf8

  $alpha1 = New-TestPackage -Identity '0.1.0-alpha.1+clean' -SourceDirty $false
  $candidate = New-TestPackage -Identity '0.1.0-alpha.2+candidate.dirty' -SourceDirty $true
  $alpha2 = New-TestPackage -Identity '0.1.0-alpha.2+clean' -SourceDirty $false
  $broken = New-TestPackage -Identity '0.1.0-alpha.3+broken' -SourceDirty $false
  $installer = Join-Path $PSScriptRoot '..\installer\Install-Friday.ps1'

  & $installer -PackagePath $alpha1 -InstallRoot $installRoot -DataDirectory $dataRoot -SkipStart | Out-Null
  & $installer -PackagePath $candidate -InstallRoot $installRoot -DataDirectory $dataRoot -SkipStart | Out-Null
  & $installer -PackagePath $alpha2 -InstallRoot $installRoot -DataDirectory $dataRoot -SkipStart | Out-Null
  $active = Get-Content -LiteralPath (Join-Path $installRoot 'runtime\active.json') -Raw | ConvertFrom-Json
  $releaseNames = @(Get-ChildItem -LiteralPath (Join-Path $installRoot 'runtime\releases') -Directory | Select-Object -ExpandProperty Name)
  if ($active.identity -ne '0.1.0-alpha.2+clean' -or $active.previousIdentity -ne '0.1.0-alpha.1+clean') {
    throw 'La release propre ne conserve pas la précédente release propre.'
  }
  if ($releaseNames.Count -ne 2 -or $releaseNames -contains '0.1.0-alpha.2+candidate.dirty') {
    throw 'Le candidat dirty n''a pas été retiré après installation propre.'
  }

  try {
    & $installer -PackagePath $broken -InstallRoot $installRoot -DataDirectory $dataRoot | Out-Null
    throw 'L''échec de démarrage simulé aurait dû interrompre l''installation.'
  }
  catch {
    if ($_.Exception.Message -notmatch 'SIMULATED_START_FAILURE') { throw }
  }
  $rolledBack = Get-Content -LiteralPath (Join-Path $installRoot 'runtime\active.json') -Raw | ConvertFrom-Json
  if ($rolledBack.identity -ne '0.1.0-alpha.2+clean') { throw 'Le rollback n''a pas restauré la release active.' }
  Write-Output 'Installation, conservation propre et rollback validés.'
}
finally {
  if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}
