[CmdletBinding()]
param(
  [string]$InstallRoot = 'D:\Friday',
  [string]$DataDirectory = 'D:\FridayData'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
Write-Host 'Friday — diagnostic local' -ForegroundColor Cyan
& (Join-Path $InstallRoot 'installer\Get-FridayStatus.ps1') -InstallRoot $InstallRoot -DataDirectory $DataDirectory | Format-List *
Write-Host "Données présentes : $(Test-Path -LiteralPath (Join-Path $DataDirectory 'friday.sqlite'))"
Write-Host "Configuration présente : $(Test-Path -LiteralPath (Join-Path $DataDirectory 'config\instance.json'))"
Write-Host "Tâche de démarrage : $([bool](Get-ScheduledTask -TaskName 'Friday' -ErrorAction SilentlyContinue))"
Read-Host 'Entrée pour fermer' | Out-Null
