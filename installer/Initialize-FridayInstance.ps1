[CmdletBinding()]
param([string]$DataDirectory = 'D:\FridayData')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$configDirectory = Join-Path $DataDirectory 'config'
$secretsDirectory = Join-Path $DataDirectory 'secrets'
$deploymentDirectory = Join-Path $DataDirectory 'deployment'
New-Item -ItemType Directory -Path $configDirectory, $secretsDirectory, $deploymentDirectory -Force | Out-Null
$configPath = Join-Path $configDirectory 'instance.json'
if (-not (Test-Path -LiteralPath $configPath)) {
  $configuration = [ordered]@{
    format = 1
    dataDirectory = $DataDirectory
    host = '127.0.0.1'
    port = 8443
    publicOrigin = 'http://127.0.0.1:8443'
    trustedOrigins = @('http://127.0.0.1:8443')
    tls = [ordered]@{
      enabled = $false
      certificatePath = Join-Path $DataDirectory 'certificates\friday-lan.pem'
      keyPath = Join-Path $DataDirectory 'secrets\friday-lan-key.pem'
    }
    features = [ordered]@{
      chatEnabled = $true
      chatAxesEnabled = $true
      chatPipeline = 'unified'
      robotEnabled = $false
    }
    ollama = [ordered]@{ url = 'http://127.0.0.1:11434'; required = $false }
    models = [ordered]@{ groceryClassification = 'ministral-3:8b'; groceryPhoto = 'qwen3.5:9b-q4_K_M' }
  }
  $configuration | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $configPath -Encoding utf8
}
$existingTavily = [Environment]::GetEnvironmentVariable('FRIDAY_TAVILY_API_KEY', 'User')
$tavilyPath = Join-Path $secretsDirectory 'tavily-api-key'
if ($existingTavily -and -not (Test-Path -LiteralPath $tavilyPath)) {
  Set-Content -LiteralPath $tavilyPath -Value $existingTavily -NoNewline -Encoding utf8
}
Get-Item -LiteralPath $configPath
