[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$required = @(
  'README.md',
  'channel.json',
  'docs\README.md',
  'docs\installation.md',
  'docs\utilisation.md',
  'docs\confidentialite-locale.md',
  'installer\Install-Friday.ps1',
  'installer\Start-Friday.ps1',
  'installer\Configure-FridayLan.ps1'
)
foreach ($relativePath in $required) {
  if (-not (Test-Path -LiteralPath (Join-Path $RepositoryRoot $relativePath) -PathType Leaf)) {
    throw "Fichier public obligatoire absent : $relativePath"
  }
}

$trackedFiles = @(
  & git -C $RepositoryRoot ls-files
  & git -C $RepositoryRoot ls-files --others --exclude-standard
) | Sort-Object -Unique
if ($LASTEXITCODE -ne 0) { throw 'Impossible de lire les fichiers suivis par Git.' }
$forbiddenFile = $trackedFiles | Where-Object {
  $_ -match '(^|/)(runtime|packages)/' -or $_ -match '\.(zip|sqlite|pem|key|pfx|p12|ts|tsx|map)$'
} | Select-Object -First 1
if ($forbiddenFile) { throw "Fichier interdit dans le dépôt public : $forbiddenFile" }

$privateSourcePath = 'D:\prog\' + 'friday'
$privateRepository = 'Sharpsou/' + 'fridayTS'
$householdAddress = @('192', '168', '1', '14') -join '.'
foreach ($relativePath in $trackedFiles | Where-Object { $_ -match '\.(md|json|ps1|yml|yaml)$' }) {
  $path = Join-Path $RepositoryRoot ($relativePath -replace '/', '\')
  $content = Get-Content -LiteralPath $path -Raw
  foreach ($forbidden in @($privateSourcePath, $privateRepository, $householdAddress)) {
    if ($content.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Information privée interdite dans $relativePath"
    }
  }
  if ($relativePath -match '\.ps1$') {
    [void][ScriptBlock]::Create($content)
  }
}

$markdownFiles = $trackedFiles | Where-Object { $_ -match '\.md$' }
foreach ($relativePath in $markdownFiles) {
  $path = Join-Path $RepositoryRoot ($relativePath -replace '/', '\')
  $content = Get-Content -LiteralPath $path -Raw
  foreach ($match in [regex]::Matches($content, '\[[^\]]+\]\((?!https?://|#)([^)#]+)(?:#[^)]+)?\)')) {
    $target = [Uri]::UnescapeDataString($match.Groups[1].Value)
    $resolved = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $path) $target))
    if (-not (Test-Path -LiteralPath $resolved)) {
      throw "Lien interne absent dans $relativePath : $target"
    }
  }
}

$channel = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'channel.json') -Raw | ConvertFrom-Json
if ($channel.published -ne $false -or $null -ne $channel.latest) {
  throw 'Le canal alpha doit rester non publié sans binaire signé.'
}
Write-Output "Distribution Friday valide : $($trackedFiles.Count) fichiers suivis."
