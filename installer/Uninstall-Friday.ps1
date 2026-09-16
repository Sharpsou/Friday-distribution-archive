[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param([string]$InstallRoot = 'D:\Friday')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
& (Join-Path $InstallRoot 'installer\Stop-Friday.ps1') -InstallRoot $InstallRoot
Unregister-ScheduledTask -TaskName 'Friday' -Confirm:$false -ErrorAction SilentlyContinue
if ($PSCmdlet.ShouldProcess((Join-Path $InstallRoot 'runtime'), 'Supprimer le runtime Friday sans toucher aux données')) {
  Remove-Item -LiteralPath (Join-Path $InstallRoot 'runtime') -Recurse -Force -ErrorAction SilentlyContinue
}
