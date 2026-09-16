[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$PackagePath,
  [string]$InstallRoot = 'D:\Friday',
  [string]$DataDirectory = 'D:\FridayData',
  [string]$ExpectedArchiveSha256,
  [switch]$SkipStart
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$runtimeRoot = Join-Path $InstallRoot 'runtime'
$releasesRoot = Join-Path $runtimeRoot 'releases'
$activePath = Join-Path $runtimeRoot 'active.json'
$stagingRoot = Join-Path $runtimeRoot ('.staging-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $releasesRoot -Force | Out-Null
$oldActive = if (Test-Path -LiteralPath $activePath) { Get-Content -LiteralPath $activePath -Raw | ConvertFrom-Json } else { $null }

try {
  if ($ExpectedArchiveSha256) {
    $actualArchiveSha256 = (Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash
    if ($actualArchiveSha256 -ne $ExpectedArchiveSha256) { throw "Empreinte SHA-256 de l'archive incorrecte." }
  }
  if ((Get-Item -LiteralPath $PackagePath).PSIsContainer) { Copy-Item -LiteralPath $PackagePath -Destination $stagingRoot -Recurse }
  else { Expand-Archive -LiteralPath $PackagePath -DestinationPath $stagingRoot }
  $manifestPath = Get-ChildItem -LiteralPath $stagingRoot -Filter manifest.json -Recurse -File | Select-Object -First 1 -ExpandProperty FullName
  if (-not $manifestPath) { throw "manifest.json absent de l'artefact." }
  $candidateRoot = Split-Path -Parent $manifestPath
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
  foreach ($file in $manifest.files) {
    $candidateFile = Join-Path $candidateRoot ([string]$file.path -replace '/', '\')
    if (-not (Test-Path -LiteralPath $candidateFile -PathType Leaf)) { throw "Fichier absent : $($file.path)" }
    $actual = (Get-FileHash -LiteralPath $candidateFile -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne [string]$file.sha256) { throw "Empreinte incorrecte : $($file.path)" }
  }
  $forbidden = Get-ChildItem -LiteralPath $candidateRoot -Recurse -File | Where-Object { $_.Name -match '\.(ts|tsx|map)$' }
  if ($forbidden) { throw "Source interdite dans l'artefact : $($forbidden[0].FullName)" }
  $releaseName = ([string]$manifest.identity -replace '[^A-Za-z0-9._+-]', '-')
  $releasePath = Join-Path $releasesRoot $releaseName
  if (Test-Path -LiteralPath $releasePath) { Remove-Item -LiteralPath $releasePath -Recurse -Force }
  Move-Item -LiteralPath $candidateRoot -Destination $releasePath
  $active = [ordered]@{
    format = 1
    identity = [string]$manifest.identity
    releasePath = $releasePath
    previousIdentity = if ($oldActive) { [string]$oldActive.identity } else { $null }
    previousReleasePath = if ($oldActive) { [string]$oldActive.releasePath } else { $null }
    activatedAtUtc = [DateTime]::UtcNow.ToString('o')
  }
  $active | ConvertTo-Json | Set-Content -LiteralPath $activePath -Encoding utf8
  New-Item -ItemType Directory -Path (Join-Path $DataDirectory 'deployment') -Force | Out-Null
  $active | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $DataDirectory 'deployment\current.json') -Encoding utf8
  if (-not $SkipStart) {
    try { & (Join-Path $InstallRoot 'installer\Start-Friday.ps1') -InstallRoot $InstallRoot -DataDirectory $DataDirectory -RestartExisting | Out-Null }
    catch {
      if ($oldActive) {
        $oldActive | ConvertTo-Json | Set-Content -LiteralPath $activePath -Encoding utf8
        $oldActive | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $DataDirectory 'deployment\current.json') -Encoding utf8
        & (Join-Path $InstallRoot 'installer\Start-Friday.ps1') -InstallRoot $InstallRoot -DataDirectory $DataDirectory -RestartExisting | Out-Null
      }
      else {
        Remove-Item -LiteralPath $activePath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $DataDirectory 'deployment\current.json') -Force -ErrorAction SilentlyContinue
      }
      throw "Installation annulée et retour arrière effectué : $($_.Exception.Message)"
    }
  }
  [PSCustomObject]@{ installed = $true; identity = $manifest.identity; releasePath = $releasePath }
}
finally {
  if (Test-Path -LiteralPath $stagingRoot) { Remove-Item -LiteralPath $stagingRoot -Recurse -Force }
}
