[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param([string]$DataDirectory = 'D:\FridayData')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
if ($PSCmdlet.ShouldProcess($DataDirectory, "Restreindre les ACL à $($identity.Name), SYSTEM et Administrateurs")) {
  $root = [IO.Path]::GetFullPath($DataDirectory).TrimEnd('\')
  if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Dossier de données absent : $root" }
  & icacls.exe $root /inheritance:r /grant:r "$($identity.Name):(OI)(CI)F" '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' /remove:g '*S-1-5-11' '*S-1-5-32-545' /Q | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Protection de la racine impossible (code $LASTEXITCODE)." }

  $directories = [Collections.Generic.Stack[string]]::new()
  $directories.Push($root)
  $processed = 0
  $skippedLinks = 0
  $denied = [Collections.Generic.List[string]]::new()
  while ($directories.Count -gt 0) {
    $directory = $directories.Pop()
    foreach ($path in [IO.Directory]::EnumerateFileSystemEntries($directory)) {
      $item = Get-Item -LiteralPath $path -Force
      if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        $skippedLinks += 1
        continue
      }
      try {
        $acl = [IO.FileSystemAclExtensions]::GetAccessControl(
          $item,
          [Security.AccessControl.AccessControlSections]::Access
        )
        $acl.SetAccessRuleProtection($false, $true)
        [IO.FileSystemAclExtensions]::SetAccessControl($item, $acl)
      }
      catch {
        $denied.Add($path)
        continue
      }
      $processed += 1
      if ($item.PSIsContainer) { $directories.Push($path) }
    }
  }
  if ($denied.Count -gt 0) {
    Write-Warning "ACL incomplètes sur $($denied.Count) chemin(s). Relancer ce script dans un terminal administrateur."
  }
  [PSCustomObject]@{
    protected = $root
    processed = $processed
    skippedLinks = $skippedLinks
    denied = @($denied)
    complete = $denied.Count -eq 0
  }
}
