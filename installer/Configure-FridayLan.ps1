[CmdletBinding()]
param(
  [string]$DataDirectory = 'D:\FridayData',
  [string]$PublicOrigin,
  [string]$CertificatePath,
  [string]$KeyPath,
  [string[]]$TrustedOrigins
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$configPath = Join-Path $DataDirectory 'config\instance.json'
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
  throw "Configuration Friday absente : $configPath"
}
if (-not $PublicOrigin) { $PublicOrigin = Read-Host 'Origine HTTPS Friday (ex. https://friday.maison:8443)' }
if (-not $CertificatePath) { $CertificatePath = Read-Host 'Chemin du certificat serveur public' }
if (-not $KeyPath) { $KeyPath = Read-Host 'Chemin de la clé privée du certificat' }

$origin = $null
if (-not [Uri]::TryCreate($PublicOrigin, [UriKind]::Absolute, [ref]$origin) -or $origin.Scheme -ne 'https' -or -not $origin.Host) {
  throw 'PublicOrigin doit être une origine HTTPS absolue.'
}
if ($origin.AbsolutePath -ne '/' -or $origin.Query -or $origin.Fragment) {
  throw 'PublicOrigin ne doit contenir ni chemin, ni requête, ni fragment.'
}
if (-not (Test-Path -LiteralPath $CertificatePath -PathType Leaf)) { throw "Certificat absent : $CertificatePath" }
if (-not (Test-Path -LiteralPath $KeyPath -PathType Leaf)) { throw "Clé privée absente : $KeyPath" }

$configuration = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$configuration.host = '0.0.0.0'
$configuration.port = if ($origin.IsDefaultPort) { 443 } else { $origin.Port }
$configuration.publicOrigin = $origin.GetLeftPart([UriPartial]::Authority)
$origins = @($configuration.publicOrigin) + @($TrustedOrigins | Where-Object { $_ })
$configuration.trustedOrigins = @($origins | Select-Object -Unique)
$configuration.tls.enabled = $true
$configuration.tls.certificatePath = [IO.Path]::GetFullPath($CertificatePath)
$configuration.tls.keyPath = [IO.Path]::GetFullPath($KeyPath)
$configuration | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $configPath -Encoding utf8
Get-Item -LiteralPath $configPath
