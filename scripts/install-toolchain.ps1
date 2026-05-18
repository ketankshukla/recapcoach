# Full toolchain installer: Flutter (assumes already cloned) + JDK 17 + Android SDK + emulator.
# Idempotent. Run from any PowerShell. Logs to stdout.
#
# Usage:  .\scripts\install-toolchain.ps1

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # speeds up Invoke-WebRequest

function Write-Step($msg) { Write-Host ""; Write-Host "==> $msg" -ForegroundColor Cyan }

# ---------------------------------------------------------------------------
# 1. Flutter on PATH
# ---------------------------------------------------------------------------
Write-Step "Verifying Flutter clone..."
$flutterDir = "$env:USERPROFILE\flutter"
$flutterBin = "$flutterDir\bin"
if (-not (Test-Path "$flutterBin\flutter.bat")) {
    Write-Host "Cloning Flutter stable to $flutterDir ..."
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git $flutterDir
}
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$flutterBin*") {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$flutterBin", 'User')
    Write-Host "Added $flutterBin to user PATH."
}
$env:Path = "$env:Path;$flutterBin"

# ---------------------------------------------------------------------------
# 2. Bootstrap Flutter (downloads Dart SDK ~200MB on first run)
# ---------------------------------------------------------------------------
Write-Step "Bootstrapping Flutter (downloads Dart SDK on first run, ~200MB)..."
& "$flutterBin\flutter.bat" --suppress-analytics --version
& "$flutterBin\flutter.bat" --suppress-analytics config --no-analytics --no-cli-animations | Out-Null

# ---------------------------------------------------------------------------
# 3. JDK 17 (Temurin) via winget
# ---------------------------------------------------------------------------
Write-Step "Checking for JDK 17 (Temurin)..."
$jdk17Root = "$env:ProgramFiles\Eclipse Adoptium"
$jdk17 = $null
if (Test-Path $jdk17Root) {
    $jdk17 = Get-ChildItem $jdk17Root -Filter "jdk-17*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
}
if (-not $jdk17) {
    Write-Host "Installing JDK 17 via winget (you may see a UAC prompt)..."
    winget install --id EclipseAdoptium.Temurin.17.JDK --silent --accept-source-agreements --accept-package-agreements
    $jdk17 = Get-ChildItem $jdk17Root -Filter "jdk-17*" -Directory | Select-Object -First 1
}
if (-not $jdk17) { throw "JDK 17 install failed; check winget output." }
$env:JAVA_HOME = $jdk17.FullName
[Environment]::SetEnvironmentVariable('JAVA_HOME', $jdk17.FullName, 'User')
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
Write-Host "JAVA_HOME = $env:JAVA_HOME"

# ---------------------------------------------------------------------------
# 4. Android cmdline-tools
# ---------------------------------------------------------------------------
Write-Step "Setting up Android command-line tools..."
$androidHome = "$env:LOCALAPPDATA\Android\Sdk"
$cmdlineLatest = "$androidHome\cmdline-tools\latest"
$sdkmanager = "$cmdlineLatest\bin\sdkmanager.bat"

if (-not (Test-Path $sdkmanager)) {
    Write-Host "Downloading Android cmdline-tools (~150 MB)..."
    $tmpZip = "$env:TEMP\android-cmdline-tools.zip"
    $url = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
    Invoke-WebRequest -Uri $url -OutFile $tmpZip
    New-Item -ItemType Directory -Force -Path "$androidHome\cmdline-tools" | Out-Null

    $extractTmp = "$env:TEMP\android-cmdline-tools-ex"
    if (Test-Path $extractTmp) { Remove-Item -Recurse -Force $extractTmp }
    Expand-Archive -Path $tmpZip -DestinationPath $extractTmp -Force
    # Zip extracts as <root>/cmdline-tools/...; rename to 'latest'
    if (Test-Path "$cmdlineLatest") { Remove-Item -Recurse -Force $cmdlineLatest }
    Move-Item "$extractTmp\cmdline-tools" $cmdlineLatest
    Remove-Item $tmpZip
    Remove-Item -Recurse -Force $extractTmp
}

[Environment]::SetEnvironmentVariable('ANDROID_HOME', $androidHome, 'User')
[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', $androidHome, 'User')
$env:ANDROID_HOME = $androidHome
$env:ANDROID_SDK_ROOT = $androidHome
$env:Path = "$env:Path;$cmdlineLatest\bin;$androidHome\platform-tools;$androidHome\emulator"

# ---------------------------------------------------------------------------
# 5. SDK packages
# ---------------------------------------------------------------------------
Write-Step "Installing Android SDK packages (platform-tools, android-34, build-tools, emulator, system image)..."
$yes = ((1..200 | ForEach-Object { 'y' }) -join "`n")
$yes | & $sdkmanager --sdk_root=$androidHome `
    "platform-tools" `
    "platforms;android-34" `
    "platforms;android-35" `
    "build-tools;34.0.0" `
    "emulator" `
    "system-images;android-34;google_apis;x86_64"

# ---------------------------------------------------------------------------
# 6. Accept all licenses (sdkmanager + Flutter doctor)
# ---------------------------------------------------------------------------
Write-Step "Accepting Android SDK licenses..."
$yes | & $sdkmanager --sdk_root=$androidHome --licenses

Write-Step "Telling Flutter where the Android SDK + JDK are..."
& "$flutterBin\flutter.bat" config --android-sdk $androidHome --jdk-dir $env:JAVA_HOME | Out-Null

Write-Step "Accepting Flutter Android licenses (final pass)..."
$yes | & "$flutterBin\flutter.bat" --suppress-analytics doctor --android-licenses

# ---------------------------------------------------------------------------
# 7. (Optional) create a Pixel emulator
# ---------------------------------------------------------------------------
Write-Step "Creating Pixel API 34 emulator (if missing)..."
$avdmanager = "$cmdlineLatest\bin\avdmanager.bat"
$existingAvd = & $avdmanager list avd 2>$null | Select-String "Name: pixel_api34"
if (-not $existingAvd) {
    "no" | & $avdmanager create avd -n pixel_api34 `
        -k "system-images;android-34;google_apis;x86_64" `
        -d "pixel_7" --force
} else {
    Write-Host "AVD 'pixel_api34' already exists; skipping."
}

# ---------------------------------------------------------------------------
# 8. flutter doctor + project resolve
# ---------------------------------------------------------------------------
Write-Step "Final flutter doctor..."
& "$flutterBin\flutter.bat" --suppress-analytics doctor -v

Write-Step "Resolving flutter_app_kit dependencies..."
$kitDir = "E:\flutter_app_kit"
if (Test-Path $kitDir) {
    Push-Location $kitDir
    try {
        & "$flutterBin\flutter.bat" --suppress-analytics pub get
    } finally {
        Pop-Location
    }
} else {
    Write-Host "Skipping pub get; $kitDir not found."
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host " Toolchain installation complete." -ForegroundColor Green
Write-Host " Open a NEW PowerShell window so PATH/env vars are refreshed." -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
