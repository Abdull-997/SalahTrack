$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter is required. Install Flutter 3.47 or newer and put it on PATH."
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "Python is required once for platform setup."
}

python tool/apply_platform_setup.py
flutter pub get
flutter analyze
flutter test
Write-Host "SalahTrack is ready. Run: flutter run"
