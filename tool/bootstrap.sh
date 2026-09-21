#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is required. Install Flutter 3.47 or newer and put it on PATH." >&2
  exit 1
fi

python3 tool/apply_platform_setup.py
flutter pub get
flutter analyze
flutter test

echo "SalahTrack is ready. Run: flutter run"
