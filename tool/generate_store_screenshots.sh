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
  xcrun simctl bootstatus "$device" -b
  xcrun simctl list devices booted
  flutter devices --machine | python3 -c '
import json, sys
udid = sys.argv[1]
if not any(d.get("id") == udid and d.get("isSupported", True) for d in json.load(sys.stdin)):
    sys.exit(f"Flutter cannot see booted simulator {udid}")
' "$device"
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
if [[ $platform == ios ]]; then
  # The first CocoaPods/Xcode build can consume several minutes on a fresh
  # runner. Give it a separate budget before starting the screenshot watchdog.
  echo "[Store Screenshots] Building iOS screenshot test for ${locales[0]}"
  python3 - "${locales[0]}" <<'PY'
import os
import signal
import subprocess
import sys

command = [
    'flutter', 'build', 'ios', '--simulator', '--debug', '--no-pub',
    '--target=integration_test/store_screenshots_test.dart',
    f'--dart-define=STORE_LOCALE={sys.argv[1]}',
]
process = subprocess.Popen(command, start_new_session=True)
try:
    result = process.wait(timeout=600)
except subprocess.TimeoutExpired:
    print('[Store Screenshots] Initial iOS build timed out after 10 minutes',
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
  echo '[Store Screenshots] Initial iOS build finished; starting captures'
fi
for index in "${!locales[@]}"; do
  locale=${locales[$index]}
  export STORE_LOCALE=$locale
  echo "[$((index + 1))/${#locales[@]}] $locale"
  # Python is available on both GitHub-hosted runner families. A process
  # group lets the watchdog stop Flutter and any child build tools together.
  set +e
  python3 - "$locale" "$device" <<'PY'
import json
import os
import signal
import subprocess
import sys
import threading
import time

locale, device = sys.argv[1:]
command = [
    'flutter', 'drive',
    '--driver=test_driver/store_screenshots.dart',
    '--target=integration_test/store_screenshots_test.dart',
    '--no-pub',
    '-d', device,
    f'--dart-define=STORE_LOCALE={locale}',
]
process = subprocess.Popen(
    command, start_new_session=True, stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT, text=True, bufsize=1,
)
launch_failed = threading.Event()

def relay_output():
    for line in process.stdout:
        print(line, end='', flush=True)
        if any(marker in line for marker in (
            'Error launching application', 'Could not launch',
            'Failed to launch', 'Lost connection to device.',
        )):
            launch_failed.set()

reader = threading.Thread(target=relay_output, daemon=True)
reader.start()
deadline = time.monotonic() + 480
next_status = time.monotonic() + 60
try:
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise subprocess.TimeoutExpired(command, 480)
        try:
            result = process.wait(timeout=min(5, remaining))
            reader.join(timeout=2)
            break
        except subprocess.TimeoutExpired:
            if launch_failed.is_set():
                print('[Store Screenshots] Flutter reported an app launch failure',
                      file=sys.stderr, flush=True)
                os.killpg(process.pid, signal.SIGTERM)
                process.wait(timeout=10)
                sys.exit(126)
            if time.monotonic() < next_status:
                continue
            next_status = time.monotonic() + 60
            if sys.platform == 'darwin':
                try:
                    status = subprocess.run(
                        ['xcrun', 'simctl', 'list', 'devices', 'booted', '-j'],
                        capture_output=True, text=True, timeout=15,
                    )
                    devices = json.loads(status.stdout)['devices'] if status.returncode == 0 else {}
                    booted = [d['udid'] for group in devices.values() for d in group]
                except (ValueError, KeyError, subprocess.TimeoutExpired):
                    booted = []
                if device not in booted:
                    print(f'[Store Screenshots] Simulator {device} is no longer booted',
                          file=sys.stderr, flush=True)
                    os.killpg(process.pid, signal.SIGTERM)
                    process.wait(timeout=10)
                    sys.exit(125)
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
