[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param([string]$DataDirectory = 'D:\FridayData')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
if ($PSCmdlet.ShouldProcess($DataDirectory, "Restreindre les ACL à $identity, SYSTEM et Administrateurs")) {
  & icacls.exe $DataDirectory /inheritance:r /grant:r "${identity}:(OI)(CI)F" 'SYSTEM:(OI)(CI)F' 'BUILTIN\Administrators:(OI)(CI)F' /remove:g 'Authenticated Users' 'BUILTIN\Users' /T /C
  if ($LASTEXITCODE -ne 0) { throw "icacls a échoué avec le code $LASTEXITCODE." }
}
