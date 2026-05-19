$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pythonExe = Join-Path $repoRoot ".venv\Scripts\python.exe"
$serverScript = Join-Path $repoRoot "python-api-examples\non_streaming_server.py"
$checkScript = Join-Path $repoRoot "scripts\check_local_zh_server.ps1"
$modelDir = Join-Path $repoRoot "models\sherpa-onnx-paraformer-zh-2024-03-09"
$modelFile = Join-Path $modelDir "model.int8.onnx"
$tokensFile = Join-Path $modelDir "tokens.txt"
$serverPort = 6006

Write-Host "== start and check local zh server =="

foreach ($path in @($pythonExe, $serverScript, $checkScript, $modelFile, $tokensFile)) {
  if (-not (Test-Path $path)) {
    throw "Required path missing: $path"
  }
}

$listener = netstat -ano | Select-String "LISTENING" | Select-String ":$serverPort\s"
if ($listener.Count -eq 0) {
  Write-Host "[INFO] Port $serverPort not listening. Starting server..."
  Start-Process -FilePath $pythonExe `
    -ArgumentList $serverScript, '--paraformer', $modelFile, '--tokens', $tokensFile, '--port', "$serverPort" `
    -WorkingDirectory $repoRoot `
    -WindowStyle Hidden
} else {
  Write-Host "[INFO] Port $serverPort already listening. Reusing existing server."
}

for ($i = 0; $i -lt 15; $i++) {
  $listener = netstat -ano | Select-String "LISTENING" | Select-String ":$serverPort\s"
  if ($listener.Count -gt 0) {
    break
  }

  Start-Sleep -Seconds 1
}

if ($listener.Count -eq 0) {
  throw "Server did not start listening on port $serverPort"
}

Write-Host "[INFO] Server is listening. Running self-check..."
powershell -ExecutionPolicy Bypass -File $checkScript

if ($LASTEXITCODE -ne 0) {
  throw "Self-check failed with exit code: $LASTEXITCODE"
}

Write-Host "== start and check done =="
