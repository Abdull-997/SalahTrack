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
  adb -s "$device" reverse tcp:48765 tcp:48765
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
  locales=("${all_locales[@]}")
fi
for locale in "${locales[@]}"; do
  [[ " ${all_locales[*]} " == *" $locale "* ]] || {
    echo "Unsupported locale: $locale" >&2
    exit 2
  }
done

export STORE_PLATFORM=$platform
export STORE_DEVICE=$device
export STORE_OUTPUT=${STORE_OUTPUT:-store_screenshots/$platform}

for locale in "${locales[@]}"; do
  echo "Capturing $locale on $device"
  flutter drive \
    --driver=test_driver/store_screenshots.dart \
    --target=integration_test/store_screenshots_test.dart \
    -d "$device" \
    --dart-define="STORE_LOCALE=$locale"
  for file in 01_home 02_tracking 03_qibla 04_ramadan 05_settings; do
    [[ -s "$STORE_OUTPUT/$locale/$file.png" ]] || {
      echo "Missing screenshot: $STORE_OUTPUT/$locale/$file.png" >&2
      exit 1
    }
  done
done
