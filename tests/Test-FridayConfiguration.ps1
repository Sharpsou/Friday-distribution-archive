Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('friday-public-test-' + [Guid]::NewGuid().ToString('N'))
$dataRoot = Join-Path $testRoot 'data'
try {
  & (Join-Path $PSScriptRoot '..\installer\Initialize-FridayInstance.ps1') -DataDirectory $dataRoot | Out-Null
  $configPath = Join-Path $dataRoot 'config\instance.json'
  $initial = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
  if ($initial.host -ne '127.0.0.1' -or $initial.publicOrigin -ne 'http://127.0.0.1:8443') { throw 'Configuration locale initiale incorrecte.' }
  if ($initial.tls.enabled -ne $false -or $initial.features.robotEnabled -ne $false) { throw 'TLS ou Robot ne respecte pas le défaut sûr.' }

  $initial.publicOrigin = 'http://localhost:9999'
  $initial | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $configPath -Encoding utf8
  & (Join-Path $PSScriptRoot '..\installer\Initialize-FridayInstance.ps1') -DataDirectory $dataRoot | Out-Null
  $preserved = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
  if ($preserved.publicOrigin -ne 'http://localhost:9999') { throw 'Une configuration existante a été écrasée.' }

  $certificatePath = Join-Path $testRoot 'certificate.pem'
  $keyPath = Join-Path $testRoot 'server-key.pem'
  Set-Content -LiteralPath $certificatePath -Value 'test certificate'
  Set-Content -LiteralPath $keyPath -Value 'test key'
  & (Join-Path $PSScriptRoot '..\installer\Configure-FridayLan.ps1') `
    -DataDirectory $dataRoot `
    -PublicOrigin 'https://friday.example.test:9443' `
    -CertificatePath $certificatePath `
    -KeyPath $keyPath `
    -TrustedOrigins @('https://127.0.0.1:9443') | Out-Null
  $lan = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
  if ($lan.host -ne '0.0.0.0' -or $lan.port -ne 9443 -or $lan.tls.enabled -ne $true) { throw 'Configuration LAN incorrecte.' }
  if ($lan.publicOrigin -ne 'https://friday.example.test:9443') { throw 'Origine LAN incorrecte.' }
  Write-Output 'Configuration locale, préservation et assistant LAN validés.'
}
finally {
  if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}
