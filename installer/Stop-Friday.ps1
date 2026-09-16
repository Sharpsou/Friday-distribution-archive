[CmdletBinding()]
param([string]$InstallRoot = 'D:\Friday')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$releasePrefix = [IO.Path]::GetFullPath((Join-Path $InstallRoot 'runtime\releases'))
$processes = Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
  Where-Object { $_.CommandLine -and $_.CommandLine.Contains($releasePrefix, [StringComparison]::OrdinalIgnoreCase) }
foreach ($process in $processes) {
  Stop-Process -Id $process.ProcessId -ErrorAction Stop
}
[PSCustomObject]@{ stopped = @($processes).Count }
