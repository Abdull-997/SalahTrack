#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo 'Usage: tool/generate_store_screenshots.sh android|ios DEVICE_ID [locale ...]' >&2
  exit 2
}

[[ $# -ge 2 ]] || usage
platform=$1
device=$2
shift 2
[[ $platform == android || $platform == ios ]] || usage

if [[ $platform == android ]]; then
  [[ $(adb -s "$device" shell getprop ro.kernel.qemu | tr -d '\r') == 1 ]] || {
    echo 'Use an Android emulator, not a physical phone.' >&2
    exit 2
  }
  adb -s "$device" shell settings put global sysui_demo_allowed 1 >/dev/null || true
  adb -s "$device" shell am broadcast -a com.android.systemui.demo -e command enter >/dev/null || true
  adb -s "$device" shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941 >/dev/null || true
  adb -s "$device" shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false >/dev/null || true
  adb -s "$device" shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4 >/dev/null || true
else
  xcrun simctl status_bar "$device" override --time '9:41' --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
fi

all_locales=(ar de en es fr ps tr ur id bn pa fa ms)
if [[ $# -gt 0 ]]; then
  locales=("$@")
else
  read -r -a locales <<< "${STORE_LOCALES:-en de ar}"
fi
[[ ${#locales[@]} -gt 0 ]] || { echo 'No locales requested.' >&2; exit 2; }
for locale in "${locales[@]}"; do
  [[ " ${all_locales[*]} " == *" $locale "* ]] || {
    echo "Unsupported locale: $locale" >&2
    exit 2
  }
done

export STORE_OUTPUT=${STORE_OUTPUT:-store_screenshots/$platform}

echo "[Store Screenshots] Starting $platform capture on $device (${#locales[@]} locales)"
for index in "${!locales[@]}"; do
  locale=${locales[$index]}
  export STORE_LOCALE=$locale
  echo "[$((index + 1))/${#locales[@]}] $locale"
  # Python is available on both GitHub-hosted runner families. A process
  # group lets the watchdog stop Flutter and any child build tools together.
  set +e
  python3 - "$locale" "$device" <<'PY'
import os
import signal
import subprocess
import sys
import time

locale, device = sys.argv[1:]
command = [
    'flutter', 'drive',
    '--driver=test_driver/store_screenshots.dart',
    '--target=integration_test/store_screenshots_test.dart',
    '-d', device,
    f'--dart-define=STORE_LOCALE={locale}',
]
process = subprocess.Popen(command, start_new_session=True)
deadline = time.monotonic() + 480
try:
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise subprocess.TimeoutExpired(command, 480)
        try:
            result = process.wait(timeout=min(60, remaining))
            break
        except subprocess.TimeoutExpired:
            if time.monotonic() < deadline:
                print(f'[Store Screenshots] Still capturing {locale} on {device}...',
                      flush=True)
except subprocess.TimeoutExpired:
    print(f'[Store Screenshots] Timed out after 8 minutes: {locale} on {device}',
          file=sys.stderr, flush=True)
    os.killpg(process.pid, signal.SIGTERM)
    try:
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()
    sys.exit(124)
sys.exit(result)
PY
  drive_status=$?
  set -e
  if [[ $drive_status -ne 0 ]]; then
    for file in 01_home 02_tracking 03_qibla 04_ramadan 05_settings; do
      if [[ ! -s "$STORE_OUTPUT/$locale/$file.png" ]]; then
        echo "[Store Screenshots] $locale failed before $file.png (flutter drive exit $drive_status)." >&2
        break
      fi
    done
    exit "$drive_status"
  fi
  for file in 01_home 02_tracking 03_qibla 04_ramadan 05_settings; do
    [[ -s "$STORE_OUTPUT/$locale/$file.png" ]] || {
      echo "Missing screenshot: $STORE_OUTPUT/$locale/$file.png" >&2
      exit 1
    }
  done
  echo "  Completed $locale"
done
