$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$backend = Join-Path $root 'backend'
$frontend = Join-Path $root 'frontend'
$edgePath = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'

function Test-Endpoint([string]$url) {
  try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2
    return $response.StatusCode -ge 200 -and $response.StatusCode -lt 500
  } catch {
    return $false
  }
}

function Start-ProjectServer([string]$directory, [string]$title) {
  $command = "Set-Location -LiteralPath '$directory'; npm.cmd run dev"
  Start-Process -FilePath 'powershell.exe' `
    -ArgumentList @('-NoExit', '-ExecutionPolicy', 'Bypass', '-Command', $command) `
    -WindowStyle Minimized
}

if (-not (Test-Endpoint 'http://localhost:4000/health')) {
  Start-ProjectServer $backend 'PharmaTrack API'
}

if (-not (Test-Endpoint 'http://localhost:5173/login')) {
  Start-ProjectServer $frontend 'PharmaTrack frontend'
}

$deadline = (Get-Date).AddSeconds(60)
while ((Get-Date) -lt $deadline) {
  if ((Test-Endpoint 'http://localhost:4000/health') -and (Test-Endpoint 'http://localhost:5173/login')) {
    break
  }
  Start-Sleep -Seconds 2
}

if (-not (Test-Endpoint 'http://localhost:4000/health')) {
  throw 'PharmaTrack API did not start. Check the minimized backend terminal for details.'
}
if (-not (Test-Endpoint 'http://localhost:5173/login')) {
  throw 'PharmaTrack frontend did not start. Check the minimized frontend terminal for details.'
}

if (Test-Path $edgePath) {
  Start-Process -FilePath $edgePath -ArgumentList '--app=http://localhost:5173'
} else {
  Start-Process 'http://localhost:5173'
}
