# Installs Flutter SDK on Windows 11 (PowerShell).
# Run from an elevated PowerShell prompt:  .\scripts\install-flutter.ps1
# Idempotent: safe to re-run.

$ErrorActionPreference = 'Stop'

$flutterDir = "C:\src\flutter"
$flutterBin = "$flutterDir\bin"
$gitUrl = 'https://github.com/flutter/flutter.git'

Write-Host "==> Ensuring git is installed..."
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "git not found. Install Git for Windows first: https://git-scm.com/download/win"
    exit 1
}

if (-not (Test-Path $flutterDir)) {
    Write-Host "==> Cloning Flutter stable to $flutterDir ..."
    New-Item -ItemType Directory -Force -Path "C:\src" | Out-Null
    git clone -b stable $gitUrl $flutterDir
} else {
    Write-Host "==> Flutter already present at $flutterDir; pulling latest stable..."
    Push-Location $flutterDir
    git checkout stable
    git pull
    Pop-Location
}

Write-Host "==> Adding Flutter to user PATH (persistent)..."
$currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($currentPath -notlike "*$flutterBin*") {
    [Environment]::SetEnvironmentVariable('Path', "$currentPath;$flutterBin", 'User')
    Write-Host "    Added $flutterBin to user PATH."
} else {
    Write-Host "    Flutter already on PATH."
}

# Apply to current session too
$env:Path = "$env:Path;$flutterBin"

Write-Host "==> Running flutter doctor (downloads Dart SDK + checks toolchain)..."
& "$flutterBin\flutter.bat" doctor

Write-Host ""
Write-Host "===================================================="
Write-Host "  Flutter installed."
Write-Host "  Open a NEW PowerShell window so PATH is refreshed."
Write-Host "  Then run:  flutter doctor"
Write-Host "  Resolve any Android licenses with:"
Write-Host "    flutter doctor --android-licenses"
Write-Host "===================================================="
