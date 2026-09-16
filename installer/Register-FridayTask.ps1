[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$InstallRoot = 'D:\Friday',
  [string]$DataDirectory = 'D:\FridayData',
  [string]$TaskName = 'Friday'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $InstallRoot 'installer\Start-Friday.ps1'
$arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -InstallRoot `"$InstallRoot`" -DataDirectory `"$DataDirectory`" -Foreground"
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arguments
$identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $identity
$trigger.Delay = 'PT30S'
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero)
$definition = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings
if ($PSCmdlet.ShouldProcess($TaskName, 'Créer ou mettre à jour la tâche de démarrage Friday')) {
  Register-ScheduledTask -TaskName $TaskName -InputObject $definition -User $identity -Force | Out-Null
}
