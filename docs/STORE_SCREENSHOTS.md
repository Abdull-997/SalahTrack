# Store screenshots

Run this from the SalahTrack Flutter project root with Flutter 3.47.4 or a
compatible later version. Install dependencies with `flutter pub get` first.
The script runs one integration test per locale and produces five PNGs in each
locale directory.

```bash
# Android emulator (find the serial with `flutter devices` or `adb devices`)
bash tool/generate_store_screenshots.sh android emulator-5554

# macOS, with an already installed and bootable iPhone simulator
bash tool/generate_store_screenshots.sh ios SIMULATOR_UDID

# Quick validation of three locales
bash tool/generate_store_screenshots.sh android emulator-5554 en de ar

# Optional output root for a separate capture set
STORE_OUTPUT=store_screenshots/iphone bash tool/generate_store_screenshots.sh ios SIMULATOR_UDID
```

The default output roots are `store_screenshots/android/` and
`store_screenshots/ios/`, followed by the locale and filename:
`en/01_home.png`, `en/02_tracking.png`, `en/03_qibla.png`,
`en/04_ramadan.png`, `en/05_settings.png`. The same names are used for all
13 locales: `ar de en es fr ps tr ur id bn pa fa ms`. The script's optional
locale arguments select a subset; with none, it uses `STORE_LOCALES` or defaults
to `en de ar`. Pass all 13 codes to capture the complete set. It rejects an
unsupported code.

Use a **Pixel 8 phone AVD**, Android API 34, Google APIs, portrait, at its
unmodified 1080 × 2400 display size for Google Play phone screenshots. The manual
GitHub workflow uses this profile and installs Android platform 36 for the app's
compile SDK. For Apple, use an **iPhone 16 Pro Max**
simulator in portrait when that runtime is installed; its native screenshot
size is 1320 × 2868 pixels. The current iOS project targets both iPhone and
iPad (`TARGETED_DEVICE_FAMILY = 1,2`). For an iPad set, use a **13-inch iPad
Pro** simulator in portrait (2064 × 2752 pixels for the M4 model). Simulator
models and available runtimes vary by Xcode version. The manual workflow
prefers an available iPhone Pro Max and 13-inch iPad and checks their native
dimensions against App Store Connect's accepted phone and 13-inch iPad sizes.
Check the actual PNG dimensions again before upload.

The screenshot test launches `SalahTrackApp` with the normal router, shell,
home, tracker, Qibla, Ramadan section, and settings widgets. Riverpod test
overrides supply Berlin as the fixed location, a March 2026 Ramadan day,
fixed prayer and tracking records, a fixed clock, and a fixed compass heading.
The test sets the selected app locale in initial preferences. It verifies that
the resulting `AppStrings` locale and `Directionality` match, including RTL
for Arabic, Urdu, Pashto, Persian, and Shahmukhi Punjabi. It waits for screen
rendering and checks a visible screen marker before each capture. At each
capture point, the integration test sends screenshot bytes to the host
integration driver, which verifies the PNG and saves it without resizing. The
script sets a
9:41 demo status bar where the emulator or simulator supports it.

Demo data exists only in `integration_test/store_screenshots_test.dart` and
its provider overrides. The screenshot mode provider defaults to `false`.
Normal `main.dart` never enables it and continues to use the live repositories,
database, location, prayer calculation, compass, and notification services.
During the integration test, startup side effects are skipped, so it does not
request permissions, schedule reminders, or write demo records to the user's
database or preferences. Use a fresh emulator or simulator for clean results.

To add another screenshot, navigate to its real route or scroll to its real
widget in `integration_test/store_screenshots_test.dart`, assert the target is
visible, and call `_capture('$_locale/06_name')`. Update the
expected filename list in `tool/generate_store_screenshots.sh` and this page.
To add a locale, first add its actual app translations and locale metadata,
then add its code to `all_locales` in the script. The test will validate it
against the app's `appLanguages` list.

Upload the `store_screenshots/android/<locale>/*.png` files from the Pixel 8
run to **Google Play Console phone screenshots**, matching each Play listing
language to its directory. Upload `store_screenshots/ios/<locale>/*.png` from
the iPhone run to **App Store Connect iPhone screenshots**. Run the script
again on an iPad simulator with a separate `STORE_OUTPUT`, then upload that
set to **App Store Connect iPad screenshots**. Inspect all images, especially
RTL layouts and long translations, before submitting. No script or workflow
uploads screenshots to either store automatically.

The separate `Store screenshots` GitHub Actions workflow is manual
(`workflow_dispatch`) and uploads Android phone, iPhone, and iPad sets as
artifacts. It does not run on pushes and does not alter the iOS release
workflow.
