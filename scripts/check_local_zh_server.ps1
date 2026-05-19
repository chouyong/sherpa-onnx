$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

$repoRoot = Split-Path -Parent $PSScriptRoot
$pythonExe = Join-Path $repoRoot ".venv\Scripts\python.exe"
$clientScript = Join-Path $repoRoot "python-api-examples\offline-websocket-client-decode-files-sequential.py"
$modelDir = Join-Path $repoRoot "models\sherpa-onnx-paraformer-zh-2024-03-09"
$modelFile = Join-Path $modelDir "model.int8.onnx"
$tokensFile = Join-Path $modelDir "tokens.txt"
$testWav = Join-Path $modelDir "test_wavs\0.wav"
$serverPort = 6006

function Assert-PathExists {
  param(
    [Parameter(Mandatory = $true)]
    [string]$PathToCheck,
    [Parameter(Mandatory = $true)]
    [string]$Label
  )

  if (-not (Test-Path $PathToCheck)) {
    throw "$Label missing: $PathToCheck"
  }

  Write-Host "[OK] $Label exists: $PathToCheck"
}

Write-Host "== sherpa-onnx local zh server check =="
Write-Host "Repo root: $repoRoot"

Assert-PathExists -PathToCheck $pythonExe -Label "Python"
Assert-PathExists -PathToCheck $clientScript -Label "WebSocket client script"
Assert-PathExists -PathToCheck $modelFile -Label "ZH int8 model"
Assert-PathExists -PathToCheck $tokensFile -Label "tokens.txt"
Assert-PathExists -PathToCheck $testWav -Label "test wav"

$listenerText = @()
for ($i = 0; $i -lt 10; $i++) {
  $listenerText = netstat -ano | Select-String "LISTENING" | Select-String ":$serverPort\s"
  if ($listenerText.Count -gt 0) {
    break
  }

  Start-Sleep -Seconds 1
}

if ($listenerText.Count -eq 0) {
  throw "Port $serverPort is not listening. Start non_streaming_server.py first."
}

Write-Host "[OK] Port listening:"
Write-Host (($listenerText | Out-String).Trim())
Write-Host "[INFO] Running WebSocket probe..."

$cmd = "`"$pythonExe`" `"$clientScript`" --server-addr 127.0.0.1 --server-port $serverPort `"$testWav`" 2>nul"
$clientOutput = cmd /c $cmd
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
  $clientOutput | Out-String | Write-Host
  throw "WebSocket probe failed with exit code: $exitCode"
}

$clientText = ($clientOutput | Out-String).Trim()
if ([string]::IsNullOrWhiteSpace($clientText)) {
  throw "WebSocket probe returned empty output"
}

Write-Host "[OK] WebSocket probe succeeded. Output:"
Write-Host $clientText
Write-Host "== check done =="
