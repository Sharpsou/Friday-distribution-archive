[CmdletBinding()]
param([string]$InstallRoot = 'D:\Friday')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$desktop = [Environment]::GetFolderPath('Desktop')
$shell = New-Object -ComObject WScript.Shell
$legacyNames = @(
  'Friday - Arreter le service.lnk',
  'Friday - Configurer acces A17.lnk',
  'Friday - Etat du service.lnk',
  'Friday - Lancer et recetter.lnk',
  'Friday - Lancer ou redemarrer.lnk'
)
foreach ($legacyName in $legacyNames) {
  Remove-Item -LiteralPath (Join-Path $desktop $legacyName) -Force -ErrorAction SilentlyContinue
}
$entries = @(
  @{ Name = 'Démarrer Friday'; Script = 'Start-Friday.ps1'; Args = '-RestartExisting' },
  @{ Name = 'Arrêter Friday'; Script = 'Stop-Friday.ps1'; Args = '' },
  @{ Name = 'État Friday'; Script = 'Get-FridayStatus.ps1'; Args = '' },
  @{ Name = 'Diagnostic Friday'; Script = 'Invoke-FridayDiagnostic.ps1'; Args = '' }
)
foreach ($entry in $entries) {
  $shortcut = $shell.CreateShortcut((Join-Path $desktop ($entry.Name + '.lnk')))
  $shortcut.TargetPath = 'powershell.exe'
  $scriptPath = Join-Path $InstallRoot ('installer\' + $entry.Script)
  $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $($entry.Args)"
  $shortcut.WorkingDirectory = $InstallRoot
  $shortcut.Save()
}
